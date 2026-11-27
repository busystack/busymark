#!/usr/bin/env bash
set -euo pipefail

readonly root="$(mktemp -d)"
trap 'rm -rf -- "$root"' EXIT

mkdir -p "$root/project/topics" "$root/project/resources" "$root/output"
cat >"$root/project/writerside.cfg" <<'XML'
<ihp><module name="Audio"/><topics dir="topics"/><resources dir="resources"/><instance src="guide.tree"/></ihp>
XML
cat >"$root/project/guide.tree" <<'XML'
<instance-profile id="guide" name="Recording guide" start-page="recording.md"><toc-element topic="recording.md"/></instance-profile>
XML
cat >"$root/project/topics/recording.md" <<'MARKDOWN'
# Recording

<resource src="tone.wav"/>

The downloadable recording contains a one-second tone.
MARKDOWN

python3 - "$root/project/resources/tone.wav" <<'PY'
import math
import struct
import sys
import wave

with wave.open(sys.argv[1], 'wb') as recording:
    recording.setparams((1, 2, 16000, 0, 'NONE', 'not compressed'))
    recording.writeframes(b''.join(
        struct.pack('<h', round(math.sin(i * 2 * math.pi * 440 / 16000) * 2400))
        for i in range(16000)
    ))
PY

WRITERSIDE_CONFORMANCE_OUTPUT="$root/output" \
    bash tools/validate_writerside_conformance.sh "$root/project" Audio/guide
python3 - "$root/output" "$root/project/resources/tone.wav" <<'PY'
from pathlib import Path
import sys
import zipfile

output = Path(sys.argv[1])
expected = Path(sys.argv[2]).read_bytes()
archives = list(output.glob('webHelp*-all.zip'))
assert len(archives) == 1, archives
with zipfile.ZipFile(archives[0]) as archive:
    audio = next(name for name in archive.namelist() if name.endswith('resources/tone.wav'))
    assert archive.read(audio) == expected
    article = next(name for name in archive.namelist() if name.endswith('recording.html'))
    assert b'resources/tone.wav' in archive.read(article)
print('Official Writerside output contains the link and original recording bytes.')
PY
