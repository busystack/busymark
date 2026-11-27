# Speech engines and provider contracts

Contracts checked against the linked official sources on 2026-11-27. BusyMark
projects the selected document scope before it calls a provider. Speech
settings and the speech usage ledger are independent of text editing and commit
messages. OpenAI and Gemini use their existing keys in the Linux credential
vault. ElevenLabs uses the single purpose
`busymark.speech.provider-key.elevenlabs` entry through the same vault.

| Engine | Release, endpoint, and local limits |
| --- | --- |
| Speech Dispatcher | Local Unix socket using SSIP. Discover actual output modules and synthesis voices. Play plain UTF-8 with completion notifications. Pause, resume, and cancel address the BusyMark connection. Configured remote or unknown modules require consent. Export is unavailable for this playback service. [SSIP](https://github.com/brailcom/speechd/blob/master/doc/ssip.texi), [spd-say](https://github.com/brailcom/speechd/blob/master/doc/spd-say.texi) |
| eSpeak NG | Supervised official `espeak-ng` with UTF-8 stdin, discovered language voices, explicit rate/pitch and WAV stdout. Ubuntu package and companion data originate from the build environment. [eSpeak NG CLI](https://github.com/espeak-ng/espeak-ng/blob/master/src/espeak-ng.1.ronn) |
| Piper | Unmodified OHF Voice `piper-tts` 1.8.0, GPL-3.0-or-later, with hashed official Python dependencies in the packaging lock. The first-party helper loads the configured model once per job and uses stdin/stdout with `PiperVoice.synthesize_wav`. No local HTTP port is opened. [Released Python API](https://github.com/OHF-Voice/piper1-gpl/blob/v1.8.0/docs/API_PYTHON.md), [released HTTP API](https://github.com/OHF-Voice/piper1-gpl/blob/v1.8.0/docs/API_HTTP.md) |
| Gemini Developer API | `gemini-3.8-flash-lite-tts` and `gemini-3.8-flash-tts` with `POST /v1beta/interactions`. The input contains spoken text and optional `speech_metadata`. Unary requests explicitly select WAV. Streaming selects linear PCM and requires a completed interaction. The adapter checks audio metadata and bytes, sends `store:false` and discovers prebuilt voices. Flash-Lite serves up to 8,192 input and 16,384 output tokens. BusyMark splits input at a lower 2,048-byte bound. [Speech API](https://aistudio.google.com/docs/speech-generation), [Flash-Lite limits](https://aistudio.google.com/docs/models/gemini-3.8-flash-lite-tts), [pricing](https://aistudio.google.com/docs/pricing#gemini-3.8-flash-lite-tts) |
| OpenAI | `gpt-realtime-2.1-mini`, authenticated WebSocket `/v1/realtime`. Text-only out-of-band requests negotiate 24 kHz mono PCM, with automatic turns and tools disabled. A completed response, correlated audio, and transcript agreement are mandatory. Transcript comparison tolerates case, punctuation and specified small English/French number forms, with signed and structured numeric values checked separately. The client caps input at 600 bytes and output at 1,536 tokens per request. The protocol caps an explicitly numeric output limit at 4,096. [Migration](https://developers.openai.com/api/docs/guides/text-to-speech), [client events](https://developers.openai.com/api/reference/resources/realtime/client-events), [server events](https://developers.openai.com/api/reference/resources/realtime/server-events), [pricing](https://developers.openai.com/api/docs/models/gpt-realtime-2.1-mini#pricing) |
| ElevenLabs | Account metadata through `GET /v1/models` and paginated `GET /v2/voices`. Synthesis uses `POST /v1/text-to-speech/{voice_id}` or its `/stream` route with `xi-api-key`. BusyMark requests 24 kHz PCM and uses the lower of its 1,800-byte input limit and any discovered bound. A language code is sent only when valid for the workflow. [Models](https://elevenlabs.io/docs/api-reference/models/list), [voices](https://elevenlabs.io/docs/api-reference/voices/search), [speech](https://elevenlabs.io/docs/api-reference/text-to-speech/convert), [streaming](https://elevenlabs.io/docs/api-reference/text-to-speech/stream) |
| Ollama | Linux speech is present for LFM3 Audio/Omni since v0.40.13. Phonon still requires Apple Silicon. The adapter uses a loopback-only origin, `/api/version`, `/api/show` for speech capabilities, and `POST /v1/audio/speech` for an explicit WAV request. [v0.40.13](https://github.com/ollama/ollama/releases/tag/v0.40.13), [v0.40.18 contract](https://github.com/ollama/ollama/blob/v0.40.18/docs/capabilities/speech.mdx), [models](https://ollama.com/library/lfm3-audio) |

## Local voices

Download pinned voices in Settings → Speech. The product installs the model,
matching JSON configuration, original `MODEL_CARD`, and provenance into
application support storage. Each downloaded file has an independent byte count
and SHA-256 bound. The staging directory is published only after all files pass.
Imported voices require the matching config and an accompanying model card.
Voice storage stays separate from document assets.

The built-in catalogue pins [piper-voices revision
cf910fb](https://huggingface.co/rhasspy/piper-voices/tree/cf910fb59f1d79ab3b625a63993a108751c6c25d).
Joe's own recordings and its rdh base use CC0. Siwis uses CC BY 4.0 for both
the SIWIS recordings and the Hi-Fi TTS reader 92 base. The pinned cards name
the actual retrained base. Preserve cards and attribution and review licensing
when adding a voice. [Piper licensing](https://github.com/OHF-Voice/piper1-gpl/blob/main/docs/LICENSING.md),
[Piper training chains](https://github.com/OHF-Voice/piper1-gpl/blob/main/docs/COMMERCIAL_USE.md).

## Composition and cancellation

The service submits bounded grapheme-safe chunks in order and normalizes
signed 16-bit PCM to 24 kHz mono. Locally inserted PCM silence represents
structural pauses. The assembled audio has one WAV header. Full synthesis
results can be replayed and saved without another request. Explicit retry can
reuse completed chunks from the same bounded job. The partial cache lives in
the job's service instance. Provider responses are never automatically retried
or routed to a different provider. The WebSocket cancellation command names the
precise out-of-band response. The local process supervisor terminates only its
owned subprocess.

## Reproducing qualification

`test/src/speech_provider_test.dart` uses in-process HTTP and WebSocket fixtures
for discovery, framing, format validation, quota, completion, cancellation
and transcript rules. `tools/speech_local_qualification_test.dart` exercises
official installed engines. Supply `SPEECH_LOCAL_ENGINE` and a private
`SPEECH_LOCAL_EVIDENCE_DIR` as Dart defines. The Piper probe accepts
`SPEECH_LOCAL_EXECUTABLE` and can prepare a voice when
`SPEECH_INSTALL_VOICE=true`. Use `SPEECH_LOCAL_LANGUAGE=fr` to exercise the
French Unicode sample and the pinned Siwis voice.
Use `SPEECH_TEST_PIPER_FAILURES=true` with the Piper probe to exercise missing
and corrupt models, cancellation, and owned worker cleanup on Linux.

For Speech Dispatcher playback, run an owned daemon in the foreground with
its own PID file, private runtime directory, config directory and Unix socket
named `system.sock` in the evidence directory. Configure the released eSpeak
NG module with a test-owned PCM sink. An ALSA `file` PCM with a `null` slave
can write raw signed 16-bit mono frames without using the desktop audio device.
Set `SPEECHD_ADDRESS=unix_socket:<evidence directory>/system.sock` in the test
environment and pass `SPEECH_LOCAL_ENGINE=system` and `SPEECH_SYSTEM_PLAY=true`.
The fixture opens two connections, pauses, resumes and cancels the first
connection's message, and requires completion on the second. Capture the
second message's PCM, confirm its content, and terminate the owned daemon.
This verifies client isolation on a standalone host. An installed strict Snap
can expose separate availability through the socket probe.

`tools/speech_cloud_qualification_test.dart` is outside the normal test corpus.
It accepts explicit provider, language, private evidence directory, credential
file path and pricing check date. First read the current official pricing
pages. The process reads the credential directly, locks one shared ledger
through each request, reserves a conservative maximum, and writes only
redacted usage and synthetic test audio. Retain reservations with unknown
billing. Four initial requests were issued on 2026-11-27.

| Provider and language | Reported input and output tokens | Duration | Estimated paid-tier cost |
| --- | ---: | ---: | ---: |
| Gemini English | 29 and 248 | 9.890 s | US$0.001503 |
| Gemini French | 30 and 240 | 9.580 s | US$0.001455 |
| OpenAI English | 90 and 228 (164 output audio) | 8.200 s | US$0.003488 |
| OpenAI French | 92 and 203 (137 output audio) | 6.850 s | US$0.002954 |

The four reservations total US$0.40. Reported usage implies US$0.009400 at the
published paid-tier rates. Account billing and invoices were not observed.
Both OpenAI responses passed the adapter's transcript comparison. ElevenLabs
has deterministic contract checks and no live result because a credential
was unavailable.
