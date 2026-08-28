# AI editing

BusyMark provides explicit, reviewable AI editing with Local Ollama, OpenAI,
or Google Gemini. AI is disabled by default. BusyMark never starts a request in
the background and never applies generated content without review.

## Configure a provider

Open **Settings → AI**, then choose exactly one provider:

- **Local Ollama** uses a loopback origin, normally
  `http://127.0.0.1:11434`. BusyMark permits only loopback origins, follows no
  redirects, and rejects Ollama cloud models.
- **OpenAI** uses the Responses API with `store: false`.
- **Google Gemini** uses the stable Interactions API with `store: false`.

Selecting a cloud provider requires an explicit content-disclosure consent.
The API key is stored by the operating-system credential service through
libsecret. It is never written to BusyMark settings, a workspace, logs, or the
application bundle. A desktop process must still read the key to make a direct
BYOK request, so OS credential storage protects the key at rest; it does not
make a compromised desktop process trustworthy.

BusyMark uses libsecret's password API through the desktop secret service.
Access depends on the credential service made available to the packaged
application. BusyMark does not write API keys into settings, workspaces, logs,
or its application bundle.

Choose **Automatic model selection** to let BusyMark route the task among the
approved models of the selected provider, or **Fixed model** to use only the
chosen model. Routing and retries never cross provider boundaries. BusyMark
does not silently send content from Ollama to a cloud provider or from one
cloud provider to another.

**Test connection** performs an actual bounded generation and accepts the
provider only when the selected model returns the required test value. For
Ollama, BusyMark also inspects `/api/show` to verify text-generation capability
and the advertised context limit. A local model cold start is allowed up to the
documented test deadline.

Current API and privacy behavior is described by the providers in the
[OpenAI Responses API](https://developers.openai.com/api/docs/guides/responses),
[OpenAI API data controls](https://developers.openai.com/api/docs/guides/your-data),
[Gemini Interactions API](https://ai.google.dev/gemini-api/docs/interactions-overview),
and [Ollama API](https://docs.ollama.com/api/introduction) documentation.
`store: false` disables provider conversation-state storage for these BusyMark
requests; it is not a promise about every form of provider retention or the
terms of a particular account.

## Editing workflow

AI editing is available only for Markdown files and Writerside Markdown topics
in **Source** view. It is deliberately unavailable for Writerside XML, trees,
configuration, variables, categories, resources, images, and unknown text
formats. The WYSIWYG editor does not expose AI editing because flattening its
structured blocks to plain text could lose Markdown semantics.

The supported document actions are:

- Rewrite
- Shorten
- Summarize
- Change tone
- Translate
- Proofread
- Draft
- Explain code block
- Improve code block

Rewrite, Shorten, Change tone, Translate, and Proofread require a selection.
Summarize expands a partial selection to complete Markdown blocks and otherwise
summarizes the active document. Draft keeps selected notes as context and
inserts the generated Markdown after them; without a selection it uses the
nearest safe prose block as local context. Insertions move to a Markdown block
boundary rather than splitting front matter, a fence, raw markup, or another
protected construct. Code actions require the cursor or selection to be inside
one complete fenced code block. Explain inserts prose after the fence; Improve
proposes a replacement for that fence.

Every action follows the same flow:

1. BusyMark identifies the exact context and proposed replacement range.
2. The dialog discloses the provider, model, and content category being sent.
3. Output streams into a temporary proposal buffer, never the document.
4. BusyMark validates the complete candidate document and shows a unified diff.
5. The user copies, rejects, or applies the proposal.
6. An accepted proposal becomes an ordinary editor edit with normal undo and
   save behavior.

If the document or selection changes while generation is running, the proposal
is stale and cannot be applied.

## Git commit drafts

The Changes sidebar can draft a Git commit message from the complete staged
repository diff. BusyMark sends the staged patch only: it does not send the
working tree, history, unstaged content, or repository files. The generated
subject is limited to 72 characters and an optional body must be separated by
a blank line. Accepting the proposal only fills the existing commit-message
field; it never stages or commits anything.
Immediately before Apply, BusyMark reads the complete staged patch again and
compares its SHA-256 fingerprint with the exact patch used for generation. A
changed index makes the proposal stale and requires a new draft.

## Markdown integrity

For transformations of existing Markdown, BusyMark builds the full candidate
document and reparses it with the same GFM parser used by the editor. It rejects
a proposal that changes protected structure or associations, including:

- YAML front matter;
- heading, list, table, and inline-Markdown structure;
- URLs associated with links and images;
- reference-link and footnote identifiers;
- autolinks and heading attributes/IDs;
- inline code with arbitrary backtick delimiters and fenced code;
- raw HTML and Writerside markup or variables.

Improve code is the narrow exception: exactly one complete fenced block may
change, while its fence declaration and language remain fixed. The validator
is intentionally conservative. A safe prose edit can be rejected, but a model
response is never treated as trusted Markdown merely because it looks valid.

## Budgets, retries, and privacy

- Feature-specific input, total-prompt, instruction, provider output-token,
  generated-output byte, transport-byte, and absolute request-time limits are
  enforced independently. Provider-neutral prompt estimates count Unicode
  text, not UTF-8 transport bytes; providers receive output limits in tokens.
- Large whole-document summaries use at most 16 bounded section summaries and
  a final synthesis. Other actions reject oversized input rather than silently
  sending more context.
- Provider `429`, `408`, `409`, and transient `5xx` responses may be retried
  before any output is shown. BusyMark honors `Retry-After` and uses bounded
  exponential backoff with jitter.
- A request is never restarted after text has streamed because restarted output
  could be duplicated.
- At most two generations run concurrently. A newer request for the same edit
  target cancels the older request, and dialogs cancel by request ID.
- BusyMark stores only monthly aggregate request/input/output token counts by
  provider. Prompts, responses, file paths, document names, model names, and
  credentials are not written to the usage ledger.

For genuinely offline use, select Local Ollama and disable Ollama cloud support
itself with `OLLAMA_NO_CLOUD=1` or `disable_ollama_cloud: true`, as documented in
the [Ollama FAQ](https://docs.ollama.com/faq#how-can-i-disable-ollamas-cloud-features).

## Deterministic smart editing

Two related features do not invoke AI:

- **Generate/update table of contents** creates a parser-derived,
  marker-delimited TOC and updates the same generated region on later runs.
- Markdown diagnostics identify skipped heading levels, empty or vague link
  text, and empty table-header cells.

Keeping these checks deterministic follows established accessibility guidance
for [nested headings](https://www.w3.org/WAI/WCAG22/Techniques/general/G141),
[descriptive link purpose](https://www.w3.org/WAI/WCAG22/Understanding/link-purpose-in-context.html),
and [table structure](https://www.w3.org/WAI/WCAG22/Techniques/).

## Implementation and release qualification

The provider-neutral implementation lives under `lib/src/ai/`:

- provider adapters map OpenAI SSE, Gemini SSE, and Ollama NDJSON into one typed
  stream;
- the coordinator owns routing, retry, concurrency, cancellation, usage, and
  latest-write-wins behavior;
- policy and Markdown validation run independently of the provider;
- the first-party Linux credential host uses portal-compatible libsecret
  password operations without opening the global Secret Service collection;

Deterministic tests cover arbitrary UTF-8 stream boundaries, malformed and
incomplete events, redirects, response bounds, provider isolation, model
fallback, cancellation, deadlines, retries and `Retry-After`, context budgets,
credential redaction, Markdown structural invariants, source-editor apply, Git
message validation, TOC generation, and accessibility diagnostics.

Release qualification must additionally run [the AI demo](../demo/ai-editing.md)
against each exact provider/model combination intended for release. Cloud
qualification requires a deliberately supplied test credential; it is never
enabled by CI secrets implicitly. Local Ollama qualification must run with
cloud features disabled. Generated prose remains probabilistic, so release
review evaluates structural invariants and task quality rather than exact
golden strings.

The local end-to-end corpus can be executed against an installed Ollama model:

```bash
OLLAMA_NO_CLOUD=1 ollama serve
dart run tools/ai_ollama_qualification.dart --model <installed-model>
```

It performs a real generation health check and exercises all seven editing
commands, whole-document summary, both fenced-code actions, Markdown structural
validation, and staged-diff commit-message generation. It prints proposals for
human quality review and exits unsuccessfully if any structural check fails.

## Authoritative references

- [OpenAI Responses streaming](https://developers.openai.com/api/docs/guides/streaming-responses)
- [OpenAI models](https://developers.openai.com/api/docs/models)
- [Gemini Interactions streaming](https://ai.google.dev/gemini-api/docs/streaming)
- [Gemini models](https://ai.google.dev/gemini-api/docs/models)
- [Ollama chat API](https://docs.ollama.com/api/chat)
- [Ollama model details API](https://docs.ollama.com/api/show)
- [Libsecret password storage](https://gnome.pages.gitlab.gnome.org/libsecret/libsecret/password-storage.html)
- [Snap Secret Portal](https://snapcraft.io/docs/how-to-guides/snap-development/use-the-secret-portal/)
