# Audio in Markdown

Choose **Insert audio** in the main menu or command palette of an editable
Markdown document. **Copy audio file** imports a copy. For a saved local
document, **Link to audio file** references a file within the document workspace.
You can also enter an HTTPS URL. Source and Editor accept audio files from the
clipboard and through drag and drop. Save an untitled document before importing
a local copy.

Local copies go beside the Markdown file by default. To use a subdirectory,
enter a document-relative path in **Settings → Speech → Audio destination**.
Existing image destinations are independent of this setting. For Nextcloud
Notes, copied recordings are note attachments and use the note's synchronized
storage. Available cached attachments play offline in BusyMark.

## Markup and properties

New recordings use standard HTML with controls and no preload.

```html
<audio controls preload="none" src="media/recording.wav"></audio>
```

For ordered alternatives, leave off `src` on the audio element. You can include
a download link as fallback and put a transcript or text equivalent next to
the player.

```html
<audio controls preload="none" aria-label="Recorded introduction">
  <source src="media/introduction.ogg" type="audio/ogg; codecs=opus">
  <source src="media/introduction.mp3" type="audio/mpeg">
  <a href="media/introduction.mp3">Download the recording</a>
</audio>
<p><a href="transcript.md">Read the introduction transcript</a></p>
```

A direct `src` takes precedence over all nested sources. Boolean HTML attributes
are enabled by their presence. Remove `controls`, `loop`, or `muted` to switch
that property off. For example, writing `controls="false"` still enables
controls. Preview omits controls if the element does not declare them.

Use **Audio properties** in Editor to change the source markup, order of
alternatives, MIME hints, accessible label, or authored settings. The same
markup is available directly in Source. Inline audio has one selection position
in Editor, so adjacent text and table cells remain editable. Copying audio to
another document retains the recording and rebases its download link. BusyMark
fetches uncached Notes attachments through the original note's account before
copying. If the recording is unavailable, normal Paste does not insert an
audio element with a missing attachment. On local files, the properties dialog
can open the recording in the desktop's default application or show its
folder. Removing an element leaves the recording file available for other
references and document history.

## Playback

Select **Play** in Preview or Editor. The player shows elapsed time and the
duration when the decoder can determine it. Seek and playback rate appear or
become available when supported. Use the volume and mute controls without
editing the Markdown. To persist looping, add the `loop` attribute in the
markup.

Opening a document never starts a recording. For external HTTPS audio,
BusyMark asks before contacting the origin. Permission applies to that
document visit. BusyMark checks redirects against the approved origin. Finite
responses with a declared size download before playback, up to 100 MiB in two
minutes. A direct audio response without a declared size can play as it
arrives, up to 100 MiB or 30 minutes. An idle stream times out after 15 seconds.
Use **Cancel** to close a live stream. Live streams have no seek, playback rate
or loop controls. Playlist protocols
such as HLS and DASH are unsupported. Switching documents pauses the active
recording.
Starting a different recording or narration transfers the in-app transport.

File types recognized for audio include MP3, WAV, Ogg, FLAC, AAC, M4A and WebM.
Playback depends on the codec inside the container. A corrupt file or
unsupported codec can fail even if its extension looks right. If no authored
alternative plays, check the file, access permissions and codec, then use
**Retry**.

## Narration and export

[Read aloud and Generate audio](speech.md) use the spoken text from the
document. Generate audio can produce a separate WAV or insert it through
the Markdown audio workflow. Keep the original passage near a generated
recording as its text equivalent.

[HTML export](html-export.md) can package local audio as relative companion
files or embed it in a single file. It leaves remote recordings as links by
default. PDF uses a recording label and available text or a portable link.

The official Writerside builder supports downloadable resources. Put a
recording in the project's configured resources directory and use
`<resource src="recording.wav"/>` in the topic. Writerside does not define
an interactive audio element. For a Writerside topic, Generate audio can
save the WAV separately before you add it as a resource.
