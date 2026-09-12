# AI implementation and qualification

This note describes the engineering boundaries behind BusyMark's user-facing
[AI editing workflow](../local-ai.md). Keep provider setup and editing
instructions in the user guide; keep transport, policy, and release checks here.

## Components and invariants

The provider-neutral implementation lives under `lib/src/ai/`:

- provider adapters normalize OpenAI and Gemini SSE and Ollama NDJSON into one
  typed event stream;
- `AiCoordinator` owns provider-local model fallback, retry, concurrency,
  cancellation, and latest-request-wins behavior;
- `AiMarkdownEditResolver` converts the selected target and context into exact
  source ranges and safe block insertions;
- `AiPromptBuilder`, `AiPolicy`, and `AiMarkdownGuard` enforce request budgets
  and validate the complete candidate document independently of the provider;
- the Linux credential host stores cloud keys with libsecret without opening
  the global Secret Service collection.

Routing and retries never cross provider boundaries. Transient `408`, `409`,
`429`, and selected `5xx` responses may be retried before output is exposed.
`Retry-After` is honored, with bounded exponential backoff and jitter. A request
is never restarted after text has streamed because doing so could duplicate
output.

Input, prompt, instruction, output-token, generated-byte, transport-byte, and
absolute-duration limits are enforced separately. At most two generations run
concurrently. A newer request for the same target cancels the older request.

## Deterministic checks

The automated tests cover fragmented and malformed streams, redirects, response
bounds, provider isolation, fallback, cancellation, deadlines, retries,
credential redaction, context budgets, Markdown invariants, Source and Editor
application paths, commit-message validation, and packaging.

Run the normal repository checks first:

```bash
flutter analyze
flutter test
```

## Local Ollama qualification

Release qualification must exercise each exact provider/model combination that
will be supported. Cloud runs require an intentionally supplied test credential;
CI must not enable them implicitly. Generated prose is probabilistic, so review
task quality as well as structural validity.

The maintained local corpus covers all five edit targets, different context
choices, complete-document editing, and staged-diff commit-message generation:

```bash
OLLAMA_NO_CLOUD=1 ollama serve
dart run tools/ai_ollama_qualification.dart --model <installed-model>
```

The command prints proposals for human review and exits unsuccessfully when a
request fails or a structural check rejects the result.
