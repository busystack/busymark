`close-testsrc.mp4` is a generated, silent H.264 test pattern for the compiled
application's natural-close regression. It contains no third-party footage.
It is distributed under the repository's Apache-2.0 license.

Reproduce with FFmpeg's built-in `testsrc2` source:

```sh
ffmpeg -f lavfi -i testsrc2=size=320x180:rate=15 -t 10 \
  -c:v libx264 -crf 38 -pix_fmt yuv420p -movflags +faststart \
  close-testsrc.mp4
```
