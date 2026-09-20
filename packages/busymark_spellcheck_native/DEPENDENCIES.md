# Native dependency inputs

BusyMark embeds Hunspell instead of using a host installation.

- Engine: Hunspell 1.7.3
- Revision: `v1.7.3` (`c5f98152a274e25b5107101104bef632b83a0cc9`)
- Source: `https://github.com/hunspell/hunspell/archive/refs/tags/v1.7.3.tar.gz`
- SHA-256: `933be3dac6fd55f6e752331a170efb7e33800e40fae1156d8434cc8c85379a1b`
- Vendored component: `third_party/hunspell/src/hunspell/` plus upstream
  license files

The package build hook compiles the vendored engine and BusyMark wrapper into
one bundled native code asset. Pango and GLib come from the GTK SDK/runtime used
to build and run BusyMark.
