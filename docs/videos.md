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
`border-effect` presentation attributes in its embedded player:

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

The BusyMark preview and Editor view show a poster until Play is pressed, then
replace it in place with an interactive player. YouTube thumbnails are loaded
from YouTube's image host, while Vimeo thumbnails are resolved through Vimeo's
official oEmbed endpoint. An explicit `preview-src` overrides the provider
thumbnail. Local files play through the packaged WebKit/GStreamer media stack.
YouTube and Vimeo posters and players require a network connection.
`mini-player="true"` hides controls other than play/pause.

Only validated HTTPS YouTube and Vimeo video identifiers reach the hosted
player. Arbitrary schemes, unrelated hosts, absolute authored paths, and paths
escaping the project media roots are rejected. The interactive player uses an
ephemeral WebKit context with cookies, permissions, popups, context menus,
local storage, WebRTC, and unrelated network hosts blocked. It does not relax
the separate offline WebKit renderer used for MathJax and visualizations.

Markdown PDF export carries video as a first-class export node. Since PDF is
not an interactive video container, it stages a local poster image and links
HTTPS sources when available; a readable source fallback is emitted when no
poster can be staged. Writerside module export continues to use JetBrains'
official Writerside builder.

The syntax follows JetBrains' [Writerside video documentation](https://www.jetbrains.com/help/writerside/videos.html)
and [semantic markup reference](https://www.jetbrains.com/help/writerside/semantic-markup-reference.html).
