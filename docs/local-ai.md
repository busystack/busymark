# Local AI editing

BusyMark provides explicit, reviewable AI editing through a locally running
Ollama service. AI is disabled by default. BusyMark does not contain an AI
account, API key, bundled model, background assistant, or first-run model
download.

## Supported workflow

1. Open **Settings → AI**.
2. Select **Local Ollama**.
3. Keep the endpoint on a loopback origin, normally
   `http://127.0.0.1:11434`.
4. Select **Test connection**. BusyMark lists installed local models and
   selects the first available model when the previous choice is unavailable.
5. In Source or Editor view, select text and open the AI button.
6. Choose Rewrite, Shorten, Summarize, Change tone, Translate, Proofread, or
   Draft.
7. Inspect the exact context disclosure and unified diff. Apply,
   copy, or discard the proposal.

Source view exchanges Markdown with the model. Editor (WYSIWYG) view requests
plain-text output so model-produced Markdown delimiters cannot be inserted as
literal visible text; existing editor formatting remains authoritative.

Rewrite, Shorten, Change tone, Translate, and Proofread require a selection.
Summarize uses the selection when present and otherwise reads the active
document; a document summary is inserted at the cursor. Draft uses selected
notes when present and otherwise inserts at the cursor. Accepted proposals are
ordinary editor changes and participate in the existing undo and save flow.

## Local model requirement

Install and run [Ollama](https://docs.ollama.com/) separately, then install a
model that is appropriate for the machine. For example:

```bash
ollama pull gpt-oss:20b
ollama serve
```

BusyMark accepts only `http` or `https` loopback origins. It disables redirect
following and checks the current `/api/tags` inventory before every generation.
Models reported by Ollama with `remote_model` or `remote_host` metadata, and
model names ending in `:cloud` or `-cloud`, are excluded and cannot run. This
matters because a local Ollama endpoint can otherwise forward requests to an
Ollama cloud model. For defense in depth, configure Ollama itself with
`OLLAMA_NO_CLOUD=1` or `disable_ollama_cloud: true` as described in the
[official Ollama local-only guidance](https://docs.ollama.com/faq#how-can-i-disable-ollamas-cloud-features).

## Safety boundaries

- AI runs only after a user action. BusyMark performs no ambient inference.
- A selection sends only that selection. A complete document is sent only for
  an explicit document summary.
- The review dialog exposes the exact context sent to Ollama.
- Input is serialized as an untrusted JSON data field. Document text is never
  treated as an application or tool instruction.
- The model cannot execute commands, access Git, read files, browse, or invoke
  BusyMark actions.
- BusyMark validates response size and preserves fenced code, inline code, and
  link destinations for transformations. A proposal that changes protected
  content is rejected.
- A proposal becomes stale when the active document or revision changes and
  cannot then be applied.
- Requests and responses are not cached or written to a BusyMark usage log.
- Requests have bounded context, response size, connection time, stream time,
  cancellation, and latest-request-wins handling.

The selected model remains generative software. The diff is the authoritative
review surface; users remain responsible for factual and editorial review.

## Critical evaluation of the research proposal

The research correctly recommends explicit commands, minimum context,
provider-independent contracts, streaming, cancellation, revision checks,
diff-before-apply, and no silent provider fallback. Those principles are in
the implementation under `lib/src/ai/`.

The proposal's direct desktop OpenAI and Gemini key configuration was not
implemented. Both vendors' current production guidance says not to expose API
keys in client applications and to keep them on a server-side component:

- [OpenAI API key safety](https://platform.openai.com/docs/api-reference/authentication)
- [Google Gemini API key security](https://ai.google.dev/gemini-api/docs/api-key#keep-your-api-key-secure)

OS secret storage protects a key at rest but does not prevent a desktop client,
its process, or a compromised user session from extracting and using it. A
future cloud integration therefore needs an authenticated BusyMark or
organization inference gateway with policy, quotas, revocation, and
server-held provider credentials. The existing provider contract can accept
such an adapter without changing editor behavior.

The following research items are intentionally deferred rather than partially
implemented: direct cloud BYOK, automatic cross-provider routing, workspace
retrieval or embeddings, background proofreading, inline completion, web
search, commit-message generation, and persistent prompt/response caches.

## Implementation and tests

- `ai_models.dart`: immutable requests, events, usage, cancellation, and
  versioned prompts.
- `ai_policy.dart`: loopback, context, output, and Markdown preservation rules.
- `ndjson_decoder.dart`: bounded incremental UTF-8/NDJSON decoding.
- `ollama_ai_provider.dart`: model discovery and streaming `/api/chat` adapter.
- `ai_coordinator.dart`: cancellation and latest-request-wins coordination.
- `ai_edit_ui.dart`: instruction, context disclosure, streaming, diff, copy,
  stale-result, and apply UI.

Focused tests cover endpoint policy, prompt-data isolation, protected Markdown,
split UTF-8/NDJSON records, malformed and oversized streams, redirect rejection,
cloud-model rejection, completion-boundary enforcement, cancellation,
superseding requests, settings round-trips, and application through the source
editor command path. Use [the demo document](../demo/ai-editing.md) for an
interactive end-to-end check with a locally installed model.

## Authoritative protocol references

- [Ollama chat API](https://docs.ollama.com/api/chat)
- [Ollama model list API](https://docs.ollama.com/api/tags)
- [Ollama streaming format](https://docs.ollama.com/api/streaming)
- [Ollama cloud behavior](https://docs.ollama.com/cloud)
- [Ollama OpenAPI model metadata](https://github.com/ollama/ollama/blob/main/docs/openapi.yaml)
