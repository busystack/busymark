import path from 'node:path'

import { build } from 'esbuild'

const [entryPoint, outfile] = process.argv.slice(2)
if (!entryPoint || !outfile) {
  throw new Error('Usage: build_render_engines.js ENTRY OUTFILE')
}

// Bundle published packages through their public entry points. Upstream source
// files, generated parsers, configuration defaults and math modules are neither
// replaced nor rewritten by BusyMark.
await build({
  entryPoints: {
    'render-engines': entryPoint,
    'mermaid-engine': path.join(path.dirname(entryPoint), 'mermaid_renderer.js'),
    'plantuml-engine': path.join(path.dirname(entryPoint), 'plantuml_renderer.js'),
    'openapi-engine': path.join(path.dirname(entryPoint), 'openapi_renderer.js'),
    'math-engine': path.join(path.dirname(entryPoint), 'mathjax_renderer.js'),
  },
  outdir: path.dirname(outfile),
  // These are BusyMark's own operation boundaries, not upstream substitutions.
  external: ['./mermaid-engine.js', './plantuml-engine.js', './openapi-engine.js', './math-engine.js'],
  bundle: true,
  format: 'esm',
  platform: 'browser',
  target: 'safari16',
  minify: true,
})
