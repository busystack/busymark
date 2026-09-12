# AI editing

BusyMark can refine Markdown with Local Ollama, OpenAI, or Google Gemini. AI is
disabled by default. Every request is initiated explicitly, shows the content
that will be shared, and produces a proposal that you must review before it can
change the document.

## Configure a provider

Open **Settings → AI**, enable a provider, and choose a model-routing mode:

- **Local Ollama** connects only to a loopback origin, normally
  `http://127.0.0.1:11434`. BusyMark rejects redirects and Ollama cloud models.
- **OpenAI** uses the Responses API with `store: false`.
- **Google Gemini** uses the Interactions API with `store: false`.

Cloud providers require explicit consent before BusyMark sends content. Their
API keys are stored through the Linux system credential service (libsecret), not
in BusyMark settings, project files, logs, or the application bundle. Credential
storage protects a key at rest; a running desktop process still needs access to
the key to make a request.

Choose **Automatic by task** to let BusyMark select from compatible models for
the enabled provider, or **Use selected model** to use the preferred model.
Routing never crosses provider boundaries. Use **Test connection** to verify
that the configured provider and model can generate text.

## Refine Markdown

**Refine with AI** is available for ordinary Markdown files and Writerside
Markdown topics. It is not available for Writerside XML, project trees,
configuration files, variables, categories, resources, images, or unknown text
formats.

You can start it in either Source or Editor view:

1. Select content and choose **Refine with AI** from the editor context menu.
   You can also use the document or Outline actions to refine an entire document
   or a selected section.
2. Enter a specific instruction, such as “Make this paragraph concise while
   keeping its meaning.”
3. Confirm the provider and model for this request.
4. Choose **What may change** and **Context shared with AI**. These choices are
   independent: for example, BusyMark can change one block while sharing the
   complete document as context.
5. Inspect **Content to change** and **Content sent to AI**, then choose
   **Generate proposal**.
6. Review the original and suggested content. Copy the proposal, cancel it, or
   choose **Apply proposal**.

The available change targets depend on where you opened the action:

| Change target | Result |
| --- | --- |
| Selected content | Replaces the current selection. |
| Insert after current block | Inserts new Markdown at a safe block boundary. |
| Current block | Replaces the block at the selection or caret. |
| Current section | Replaces the current heading and its section content. |
| Complete document | Replaces the complete Markdown source. |

Shared context can be none, the selection, the current block, the current
section, or the complete document. BusyMark displays the exact context and its
character count before sending it. A target or context choice is omitted when
it is not available at the current location.

Applying a proposal creates a normal editor edit with ordinary undo and save
behavior. If the document changes while generation or review is in progress,
the proposal becomes stale and BusyMark will not apply it.

## Markdown safeguards

BusyMark validates the complete candidate document before enabling Apply. For
edits to existing text, it protects Markdown structure and associations such as
front matter, headings, lists, tables, links, images, identifiers, footnotes,
inline and fenced code, raw HTML, and Writerside markup or variables.

The validator is intentionally conservative, so it can reject a reasonable
prose edit that also changes protected syntax. An insertion after the current
block may introduce new Markdown, but BusyMark still parses the complete result
and places the insertion at a safe block boundary.

## Git commit-message drafts

In the Changes sidebar, **Draft with AI** sends the complete staged patch and
returns a proposed commit message. It does not send unstaged content, repository
history, or unrelated files. Applying the proposal only fills the commit-message
field; it never stages or commits changes.

BusyMark checks the staged patch again before Apply. If the index changed while
the message was generated, the proposal is stale and must be regenerated.

## Privacy and limits

- Only the context displayed for the current request is sent to the selected
  provider. BusyMark does not silently fall back to a different provider.
- `store: false` disables provider conversation-state storage for BusyMark's
  cloud requests. It does not replace the provider's retention terms or the
  policies of your account.
- Prompts, responses, file paths, document names, model names, and credentials
  are not written to BusyMark's usage ledger. The ledger stores only monthly
  aggregate request and token counts by provider.
- Requests and responses have bounded size and duration. A request can be
  retried only before generated text has been shown.

For fully local use, select Local Ollama and disable cloud support in Ollama
itself with `OLLAMA_NO_CLOUD=1` or `disable_ollama_cloud: true`, as described in
the [Ollama FAQ](https://docs.ollama.com/faq#how-can-i-disable-ollamas-cloud-features).

Maintainers can find implementation invariants and qualification commands in
[AI implementation notes](development/ai.md).

## Provider references

- [OpenAI Responses API](https://developers.openai.com/api/docs/guides/responses)
- [OpenAI API data controls](https://developers.openai.com/api/docs/guides/your-data)
- [Gemini Interactions API](https://ai.google.dev/gemini-api/docs/interactions-overview)
- [Ollama API](https://docs.ollama.com/api/introduction)
- [Libsecret password storage](https://gnome.pages.gitlab.gnome.org/libsecret/libsecret/password-storage.html)
- [Snap Secret Portal](https://snapcraft.io/docs/how-to-guides/snap-development/use-the-secret-portal/)
