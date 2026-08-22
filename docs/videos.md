# Writerside videos

BusyMark recognizes Writerside's semantic `<video>` element in Writerside
Markdown and XML `.topic` files. The element is document content rather than
trusted raw HTML, and its original source is preserved exactly when the topic
is saved.

## Sources

YouTube and Vimeo videos use an HTTPS URL:

```xml
<video src="https://youtu.be/BeJu9bMPLGU"/>
<video src="https://vimeo.com/76979871"/>
```

Local video files belong in the effective Writerside images directory. A local
video needs a preview image with the same basename, or an explicit
`preview-src`:

```xml
<video src="sample.mp4"/>
<video src="sample.mp4" preview-src="posters/sample-preview.png"/>
```

For the first example, BusyMark looks for `sample.png` beside `sample.mp4`.
Imported Writerside topics copy both the local video and an explicit preview
image. Missing sources and preview images appear in document diagnostics.

BusyMark accepts the documented `width`, `height`, `mini-player`, and
`border-effect` presentation attributes in its preview card:

```xml
<video src="sample.mp4"
       preview-src="sample.png"
       width="640"
       height="360"
       mini-player="true"
       border-effect="rounded"/>
```

Other Writerside attributes remain intact for the official Writerside build
pipeline. BusyMark does not reinterpret ordinary Markdown `<video>` HTML as a
Writerside element.

## Desktop preview and PDF

The BusyMark preview and Editor view show the configured poster with an
accessible play action. Local files open in the desktop's registered video
player; supported remote videos open in the default browser. Only HTTPS
YouTube and Vimeo hosts are launchable. Arbitrary schemes, unrelated hosts,
absolute authored paths, and paths escaping the project media roots are
rejected.

Markdown PDF export carries video as a first-class export node. It stages a
local poster image and links HTTPS sources when available; a readable source
fallback is emitted when no poster can be staged. Writerside module export
continues to use JetBrains' official Writerside builder.

The syntax follows JetBrains' [Writerside video documentation](https://www.jetbrains.com/help/writerside/videos.html)
and [semantic markup reference](https://www.jetbrains.com/help/writerside/semantic-markup-reference.html).
