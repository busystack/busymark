# Authored audio implementation references

The following references were checked on 2026-11-27.

| Contract | Implementation |
| --- | --- |
| [WHATWG audio elements](https://html.spec.whatwg.org/multipage/media.html#the-audio-element) and [source elements](https://html.spec.whatwg.org/multipage/embedded-content.html#the-source-element) | Use a common descriptor in the semantic Markdown tree. Record direct and alternative source occurrences independently. Select only the direct source when it is present. Source elements are void. Boolean playback attributes retain presence semantics. |
| [Web Content Accessibility Guidelines for prerecorded audio](https://www.w3.org/WAI/WCAG22/Understanding/audio-only-and-video-only-prerecorded.html) | Author a nearby text equivalent. Fallback children inside an audio element are preserved separately from the accessible name and transcript. |
| [GStreamer playbin](https://gstreamer.freedesktop.org/documentation/playback/playbin.html) and [playback tutorials](https://gstreamer.freedesktop.org/documentation/tutorials/playback/index.html) | The Linux host supplies native decoder state and a playback transport. The document player validates resources and resolves local paths before passing a file to the transport. |
| [WebKitGTK 4.1](https://webkitgtk.org/reference/webkit2gtk/stable/) and [WebKit's user-gesture media setting](https://webkitgtk.org/reference/webkit2gtk/stable/property.Settings.media-playback-requires-user-gesture.html) | Existing video and offline visualization hosts retain their separate behavior. Audio playback uses direct GStreamer integration. |
| [CSP media-src](https://www.w3.org/TR/CSP3/#directive-media-src) | Portable HTML permits packaged local media and exporter-owned embedded bytes. Enabling external audio adds only emitted HTTPS origins. The writer's output validator enforces the same scope and emitted media never autoplays. |
| [Notes 6.0.2 routes](https://github.com/nextcloud/notes/blob/v6.0.2/appinfo/routes.php) and [Notes 6.1.0 routes](https://github.com/nextcloud/notes/blob/v6.1.0/appinfo/routes.php) | Reuse existing capability-gated attachment upload and read operations under Notes API 1.4. Deletion remains gated by the Notes application capabilities. Keep authored query and fragment suffixes outside the attachment lookup. |
| [Writerside semantic markup](https://www.jetbrains.com/help/writerside/semantic-markup-reference.html) and [downloadable resources](https://www.jetbrains.com/help/writerside/downloadable-resources.html) | Writerside authors use `<resource src="recording.wav"/>` with a file in the configured resources directory. Source HTML audio is preserved with a diagnostic. Writerside HTML export uses downloadable recording links for authored audio. The official builder resource check uses the pinned image in `tools/validate_writerside_conformance.sh`. |

The raw HTML policy and serializer are separate. The parser stores the original
element text and binds exact file offsets to rendered occurrences. The
reference scanner matches source-positioned tokenizer candidates against actual
semantic uses so comments, code and tag-looking prose do not enter file moves
or attachment replacement. Unknown attributes can survive source round trips
without being published as executable HTML.

The managed audio limit is 100 MiB. HTML export uses its existing 16 MiB
per-asset limit, 128 MiB total asset limit and total HTML byte bound. Export
validation counts encoded data URI bytes at the publication boundary.
Container detection selects extensions and MIME values for packaged audio.
Codec and playback acceptance requires an actual decoder. Current runtime
and artifact checks are recorded separately in the release evidence.
