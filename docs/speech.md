# Read aloud and Generate audio

Use **Read aloud** for temporary playback, or **Generate audio** to review a
recording and save a WAV file. Open either command from the main menu,
command palette, or a text editor’s context menu. The outline offers the same
commands for a section. Source and Editor use the current buffer, including
unsaved edits. Choose the current selection, block, section, or document in
the narration dialog. A section ends at the next heading of the same or higher
level. Read-only documents can be read or saved as independent audio.

The dialog shows the text that will be spoken and the omitted content. The
default projection reads heading titles, visible text and descriptive link
labels, inline code, quotations, tables with column labels, task states and
image descriptions. It skips code blocks, bare links, footnotes, math, hidden
content and existing media. A transcript linked or written next to a recording
remains ordinary document text. Change the rules and pause lengths in
**Settings → Speech**.

Writerside narration uses the active instance’s resolved content, including
variables and includes. In XML topics, **Block** selects the innermost block
at the cursor and **Section** selects the enclosing chapter. The transcript
uses the topic switcher’s default variant. It starts with the first available
tab and uses the same tab key in later sets with the same group name. It
includes text in collapsed sections and applies the usual code-block rule to
collapsed code. Partial XML selections use the authored text positions. When
an expansion or encoded value cannot be mapped safely, the transcript reports
the omission. [Writerside conditional content](https://www.jetbrains.com/help/writerside/conditional-content.html),
[tabs](https://www.jetbrains.com/help/writerside/tabs.html),
[collapsible elements](https://www.jetbrains.com/help/writerside/collapsible-elements.html).

A completed file is available for repeated playback without another synthesis
request. Use **Save audio** for a separate WAV file. In an editable Markdown
document, **Insert audio** adds a standard HTML audio reference after the
chosen passage. A completed result stays available to save if the source
document changes while the job runs. The original passage remains in the
document as the text alternative.

## Set up a voice

Open **Settings → Speech**. These choices are independent of text editing and
commit-message AI.

- **eSpeak NG** works offline with the available installed voices. It supports
  synthesis speed and pitch and exports PCM WAV.
- **Piper** uses a local ONNX voice with its paired configuration and
  `MODEL_CARD`. Choose an available voice or explicitly install a voice listed
  with its download size and license. Voice files live in application storage,
  separately from document assets. Discovery and installation do not send a
  document to a provider.
- **System speech** connects to the active user's Speech Dispatcher service.
  Availability and voices depend on the installed service and its modules.
  Unverified modules may use a network service. The dialog asks before reading
  with such a module. System speech produces live playback. Strict Snap
  installations can use bundled eSpeak NG or Piper for WAV generation.
- **Gemini**, **OpenAI**, and **ElevenLabs** require a configured account
  credential and explicit generation. Gemini and OpenAI share the secure keys
  used for their text providers. ElevenLabs has its own secure entry.
- **Ollama** discovery checks the local runtime. Supported speech models must
  be available on that runtime. Existing Ollama text models remain separate.

Use **Discover engines and voices** to update the available choices. **Generate
voice sample** opens a short example for explicit playback or synthesis. Voice
selection and editing preferences do not generate audio. Playback speed applies
to audio already generated. Synthesis speed affects the next recording.

## Cloud generation and privacy

Confirm the selected provider, spoken text and size before generating. Cloud
providers may charge for accepted requests, including requests cancelled after
submission. Use the pricing link in the dialog to check current rates and the
account’s terms. The result shows provider-reported usage when available.
Actual charges are available from the provider.

BusyMark uses local semantic projection for Markdown. OpenAI Realtime returns
a transcript along with audio. BusyMark checks that transcript against the
requested text and surfaces substantial differences as a failed result.
Review generated speech before sharing.

See [Audio in Markdown](audio.md) for editing, storage and export behavior.
