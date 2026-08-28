import assert from 'node:assert'
import { readFile } from 'node:fs/promises'
import path from 'node:path'

import Ajv2019 from 'ajv/dist/2019.js'
import { build } from 'esbuild'
import jison from 'jison'
import { JSON_SCHEMA, load } from 'js-yaml'

const [entryPoint, outfile, mermaidSource, disabledMathModule] = process.argv.slice(2)
if (!entryPoint || !outfile || !mermaidSource || !disabledMathModule) {
  throw new Error(
    'Usage: build_render_engines.js ENTRY OUTFILE MERMAID_SOURCE DISABLED_MATH_MODULE',
  )
}

const diagramConfigKeys = [
  'flowchart',
  'swimlane',
  'sequence',
  'gantt',
  'journey',
  'class',
  'state',
  'er',
  'pie',
  'quadrantChart',
  'xyChart',
  'requirement',
  'mindmap',
  'ishikawa',
  'kanban',
  'timeline',
  'gitGraph',
  'c4',
  'sankey',
  'block',
  'packet',
  'treeView',
  'architecture',
  'eventmodeling',
  'radar',
  'venn',
  'cynefin',
]

function generateDefaults(schema) {
  const ajv = new Ajv2019({
    useDefaults: true,
    allowUnionTypes: true,
    strict: true,
  })
  ajv.addKeyword({ keyword: 'meta:enum', errors: false })
  ajv.addKeyword({ keyword: 'tsType', errors: false })

  assert.ok(schema.$defs)
  const baseDiagramConfig = schema.$defs.BaseDiagramConfig
  const defaults = {}
  for (const key of diagramConfigKeys) {
    const reference = schema.properties[key].$ref
    const [root, definitions, definitionName] = reference.split('/')
    assert.strictEqual(root, '#')
    assert.strictEqual(definitions, '$defs')
    const subSchema = {
      $schema: schema.$schema,
      $defs: schema.$defs,
      ...schema.$defs[definitionName],
    }
    const validate = ajv.compile(subSchema)
    defaults[key] = {}
    for (const required of subSchema.required ?? []) {
      if (
        subSchema.properties[required] === undefined &&
        baseDiagramConfig.properties[required]
      ) {
        defaults[key][required] = baseDiagramConfig.properties[required].default
      }
    }
    if (!validate(defaults[key])) {
      throw new Error(`Invalid Mermaid defaults for ${key}: ${JSON.stringify(validate.errors)}`)
    }
  }

  const validate = ajv.compile(schema)
  if (!validate(defaults)) {
    throw new Error(`Invalid Mermaid defaults: ${JSON.stringify(validate.errors)}`)
  }
  return defaults
}

const jisonPlugin = {
  name: 'jison',
  setup(buildContext) {
    buildContext.onLoad({ filter: /\.jison$/ }, async ({ path: filename }) => {
      const source = await readFile(filename, 'utf8')
      const parser = new jison.Generator(source, {
        moduleType: 'js',
        'token-stack': true,
      })
      const generated = parser.generate({ moduleMain: '() => {}' })
      return {
        contents: `${generated}\nparser.parser = parser;\nexport { parser };\nexport default parser;`,
        loader: 'js',
      }
    })
  },
}

const schemaPlugin = {
  name: 'mermaid-config-schema',
  setup(buildContext) {
    buildContext.onLoad({ filter: /config\.schema\.yaml$/ }, async (args) => {
      const source = await readFile(args.path, 'utf8')
      const schema = load(source, { filename: args.path, schema: JSON_SCHEMA })
      const value = args.suffix.includes('only-defaults') ? generateDefaults(schema) : schema
      return { contents: `export default ${JSON.stringify(value)};`, loader: 'js' }
    })
  },
}

const mermaidManifest = JSON.parse(
  await readFile(path.join(mermaidSource, 'package.json'), 'utf8'),
)

await build({
  entryPoints: [entryPoint],
  outfile,
  bundle: true,
  format: 'esm',
  platform: 'browser',
  target: 'safari16',
  minify: true,
  resolveExtensions: ['.ts', '.js', '.json', '.jison', '.yaml'],
  alias: {
    mermaid: path.join(mermaidSource, 'src', 'mermaid.ts'),
    katex: disabledMathModule,
  },
  define: {
    'injected.includeLargeFeatures': 'true',
    'injected.version': JSON.stringify(String(mermaidManifest.version)),
    'import.meta.vitest': 'undefined',
  },
  plugins: [jisonPlugin, schemaPlugin],
})
