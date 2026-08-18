import {
  render as renderPlantUmlIntoElement,
  renderToString as renderPlantUmlToString,
} from '@plantuml/core'
import { bundle } from '@scalar/json-magic/bundle'
import { normalize, validate } from '@scalar/openapi-parser'
import mermaid from 'mermaid'
import { LineCounter, parseDocument } from 'yaml'

const httpMethods = new Set([
  'get',
  'put',
  'post',
  'delete',
  'options',
  'head',
  'patch',
  'trace',
])

let renderSequence = 0

function diagnostic(error, fallbackCode) {
  const message = String(error?.message ?? error?.str ?? error ?? 'Rendering failed.')
  const location = error?.hash?.loc
  const lineMatch = message.match(/(?:line|at line)\s+(\d+)/i)
  return {
    code: String(error?.code ?? fallbackCode),
    message: message.slice(0, 2000),
    severity: 'error',
    ...(Number.isInteger(location?.first_line)
      ? { line: location.first_line, column: (location.first_column ?? 0) + 1 }
      : lineMatch
        ? { line: Number.parseInt(lineMatch[1], 10) }
        : {}),
  }
}

async function renderMermaid(source, theme) {
  mermaid.initialize({
    startOnLoad: false,
    securityLevel: 'strict',
    htmlLabels: false,
    maxTextSize: 100000,
    maxEdges: 500,
    suppressErrorRendering: true,
    deterministicIds: true,
    deterministicIDSeed: 'busymark',
    theme: 'base',
    themeVariables: theme === 'dark'
      ? {
          background: '#202124',
          primaryColor: '#303134',
          primaryTextColor: '#f1f3f4',
          primaryBorderColor: '#8ab4f8',
          lineColor: '#bdc1c6',
          secondaryColor: '#3c4043',
          tertiaryColor: '#292a2d',
        }
      : {
          background: '#ffffff',
          primaryColor: '#e8f0fe',
          primaryTextColor: '#202124',
          primaryBorderColor: '#1a73e8',
          lineColor: '#5f6368',
          secondaryColor: '#f1f3f4',
          tertiaryColor: '#ffffff',
        },
  })
  try {
    const id = `busymark-mermaid-${++renderSequence}`
    const { svg } = await mermaid.render(id, source)
    return { svg, diagnostics: [] }
  } catch (error) {
    return {
      code: 'visualization.invalidMermaid',
      message: String(error?.message ?? error ?? 'Mermaid could not render this block.'),
      diagnostics: [diagnostic(error, 'visualization.invalidMermaid')],
    }
  }
}

function renderDarkPlantUml(lines) {
  return new Promise((resolve, reject) => {
    const target = document.createElement('div')
    target.id = `busymark-plantuml-${++renderSequence}`
    target.style.cssText = 'position:fixed;left:-100000px;top:0;opacity:0;pointer-events:none'
    document.body.append(target)
    const cleanup = () => {
      observer.disconnect()
      window.clearTimeout(timeout)
      target.remove()
    }
    const observer = new MutationObserver(() => {
      const svg = target.querySelector('svg')
      if (!svg) return
      const result = new XMLSerializer().serializeToString(svg)
      cleanup()
      resolve(result)
    })
    const timeout = window.setTimeout(() => {
      cleanup()
      reject(new Error('PlantUML did not finish rendering.'))
    }, 15000)
    observer.observe(target, { childList: true, subtree: true })
    renderPlantUmlIntoElement(lines, target.id, { dark: true })
  })
}

function renderPlantUml(source, theme) {
  return new Promise((resolve) => {
    const lines = source.replace(/\r\n?/g, '\n').split('\n')
    try {
      renderPlantUmlToString(
        lines,
        async (svg) => {
          try {
            resolve({
              svg: theme === 'dark' ? await renderDarkPlantUml(lines) : svg,
              diagnostics: [],
            })
          } catch (error) {
            resolve({
              code: 'visualization.invalidPlantUml',
              message: String(error?.message ?? error ?? 'PlantUML could not render this block.'),
              diagnostics: [diagnostic(error, 'visualization.invalidPlantUml')],
            })
          }
        },
        (error) => resolve({
          code: 'visualization.invalidPlantUml',
          message: String(error ?? 'PlantUML could not render this block.'),
          diagnostics: [diagnostic(error, 'visualization.invalidPlantUml')],
        }),
      )
    } catch (error) {
      resolve({
        code: 'visualization.invalidPlantUml',
        message: String(error?.message ?? error ?? 'PlantUML could not render this block.'),
        diagnostics: [diagnostic(error, 'visualization.invalidPlantUml')],
      })
    }
  })
}

function collectReferences(value, references = new Set()) {
  if (Array.isArray(value)) {
    for (const item of value) collectReferences(item, references)
    return [...references]
  }
  if (!value || typeof value !== 'object') return [...references]
  for (const [key, item] of Object.entries(value)) {
    if (key === '$ref' && typeof item === 'string' && !item.startsWith('#')) {
      references.add(item.split('#', 1)[0])
    } else {
      collectReferences(item, references)
    }
  }
  return [...references]
}

function collectSourceReferences(value, sourceMap, path = [], references = []) {
  if (Array.isArray(value)) {
    value.forEach((item, index) => collectSourceReferences(item, sourceMap, [...path, index], references))
    return references
  }
  if (!value || typeof value !== 'object') return references
  for (const [key, item] of Object.entries(value)) {
    const itemPath = [...path, key]
    if (key === '$ref' && typeof item === 'string' && !item.startsWith('#')) {
      const node = sourceMap.document.getIn(itemPath, true)
      const position = Number.isInteger(node?.range?.[0])
        ? sourceMap.lineCounter.linePos(node.range[0])
        : undefined
      references.push({
        value: item.split('#', 1)[0],
        ...(position ? { line: position.line, column: position.col } : {}),
      })
    } else {
      collectSourceReferences(item, sourceMap, itemPath, references)
    }
  }
  return references
}

function portableDirectory(filename) {
  const index = filename.lastIndexOf('/')
  return index < 0 ? '' : filename.slice(0, index)
}

function normalizePortablePath(path) {
  const segments = []
  for (const segment of path.split('/')) {
    if (!segment || segment === '.') continue
    if (segment === '..') segments.pop()
    else segments.push(segment)
  }
  return segments.join('/')
}

function canonicalizeReferences(value, filename) {
  if (Array.isArray(value)) {
    for (const item of value) canonicalizeReferences(item, filename)
    return
  }
  if (!value || typeof value !== 'object') return
  for (const [key, item] of Object.entries(value)) {
    if (key === '$ref' && typeof item === 'string' && !item.startsWith('#')) {
      const [path, fragment] = item.split('#', 2)
      value[key] = `${normalizePortablePath(`${portableDirectory(filename)}/${decodeURIComponent(path)}`)}${fragment === undefined ? '' : `#${fragment}`}`
    } else {
      canonicalizeReferences(item, filename)
    }
  }
}

class OpenApiSourceError extends Error {
  constructor(message, diagnostics) {
    super(message)
    this.name = 'OpenApiSourceError'
    this.diagnostics = diagnostics
  }
}

function sourceDiagnostic(error, sourceMap, severity = 'error') {
  const position = error?.linePos?.[0]
    ?? (Number.isInteger(error?.pos?.[0]) ? sourceMap.lineCounter.linePos(error.pos[0]) : undefined)
  const message = String(error?.message ?? 'OpenAPI source could not be parsed.').slice(0, 2000)
  if (!sourceMap.entrypoint && position) {
    return {
      code: String(error?.code ?? 'visualization.invalidOpenApi'),
      message: sourceMap.id + ':' + position.line + ':' + position.col + ': ' + message,
      severity,
    }
  }
  return {
    code: String(error?.code ?? 'visualization.invalidOpenApi'),
    message,
    severity,
    ...(position ? { line: position.line, column: position.col } : {}),
  }
}

function createSourceMap(id, source, entrypoint) {
  const lineCounter = new LineCounter()
  const document = parseDocument(source, {
    lineCounter,
    maxAliasCount: 10000,
    merge: true,
  })
  const sourceMap = { id, document, entrypoint, lineCounter }
  const errors = document.errors.map((error) => sourceDiagnostic(error, sourceMap))
  if (errors.length > 0) {
    throw new OpenApiSourceError('OpenAPI file could not be parsed: ' + id, errors)
  }
  return {
    ...sourceMap,
    warnings: document.warnings.map((warning) => sourceDiagnostic(warning, sourceMap, 'warning')),
  }
}

function parseFile(id, source, entrypoint) {
  const sourceMap = createSourceMap(id, source, entrypoint)
  const rawSpecification = normalize(source)
  if (!rawSpecification || typeof rawSpecification !== 'object' || Array.isArray(rawSpecification)) {
    throw new Error('OpenAPI file could not be parsed: ' + id)
  }
  const specification = structuredClone(rawSpecification)
  canonicalizeReferences(specification, id)
  return {
    file: {
      dir: portableDirectory(id),
      filename: id,
      isEntrypoint: entrypoint,
      references: collectReferences(specification),
      specification,
    },
    rawSpecification,
    sourceMap,
  }
}

function validationPathSegments(path) {
  if (Array.isArray(path)) return path.map((segment) => String(segment))
  if (typeof path !== 'string' || path.length === 0 || !path.startsWith('/')) return []
  return path.slice(1).split('/').map((segment) => segment.replaceAll('~1', '/').replaceAll('~0', '~'))
}

function validationLocation(error, sourceMap) {
  const path = validationPathSegments(error?.path)
  while (path.length > 0) {
    const node = sourceMap.document.getIn(path, true)
    if (Number.isInteger(node?.range?.[0])) return sourceMap.lineCounter.linePos(node.range[0])
    path.pop()
  }
  return undefined
}

function validationDiagnostics(errors, sourceMap) {
  return (errors ?? []).slice(0, 200).map((error) => {
    const location = validationLocation(error, sourceMap)
    return {
      code: String(error?.code ?? 'visualization.invalidOpenApi'),
      message: String(error?.message ?? 'OpenAPI validation failed.').slice(0, 2000),
      severity: 'error',
      ...(location ? { line: location.line, column: location.col } : {}),
    }
  })
}

function uniqueValidationErrors(...groups) {
  const byKey = new Map()
  for (const error of groups.flat()) {
    const key = String(error?.code ?? '') + '\u0000' + String(error?.path ?? '') + '\u0000' + String(error?.message ?? '')
    if (!byKey.has(key)) byKey.set(key, error)
  }
  return [...byKey.values()]
}

async function bundleOpenApi(parsedFiles) {
  const entry = parsedFiles[0]
  const documents = new Map(
    parsedFiles.slice(1).map((parsed) => ['/' + parsed.file.filename, parsed.rawSpecification]),
  )
  return bundle(structuredClone(entry.rawSpecification), {
    origin: '/' + entry.file.filename,
    plugins: [{
      type: 'loader',
      validate: (value) => documents.has(value),
      exec: async (value) => {
        const document = documents.get(value)
        return document
          ? { ok: true, data: structuredClone(document), raw: '' }
          : { ok: false }
      },
    }],
    treeShake: false,
  })
}

function operationSummary(document) {
  const operations = []
  const tags = new Set(
    Array.isArray(document.tags)
      ? document.tags.map((tag) => tag?.name).filter((tag) => typeof tag === 'string')
      : [],
  )
  const paths = document.paths && typeof document.paths === 'object' ? document.paths : {}
  for (const [path, pathItem] of Object.entries(paths)) {
    if (!pathItem || typeof pathItem !== 'object') continue
    for (const [method, operation] of Object.entries(pathItem)) {
      if (!httpMethods.has(method.toLowerCase()) || !operation || typeof operation !== 'object') continue
      const operationTags = Array.isArray(operation.tags)
        ? operation.tags.filter((tag) => typeof tag === 'string')
        : []
      for (const tag of operationTags) tags.add(tag)
      operations.push({
        method: method.toUpperCase(),
        path,
        summary: typeof operation.summary === 'string' ? operation.summary : '',
        operationId: typeof operation.operationId === 'string' ? operation.operationId : '',
        tags: operationTags,
      })
    }
  }
  operations.sort((left, right) => left.path.localeCompare(right.path) || left.method.localeCompare(right.method))
  return { operations, tags: [...tags].sort(), pathCount: Object.keys(paths).length }
}

export async function prepareOpenApi(request) {
  const entryId = request.entryId || 'document.openapi'
  const parsedFiles = [
    parseFile(entryId, request.source, true),
    ...(request.dependencies ?? []).map((dependency) => parseFile(dependency.id, dependency.source, false)),
  ]
  const files = parsedFiles.map((parsed) => parsed.file)
  const validation = await validate(files)
  const bundledDocument = await bundleOpenApi(parsedFiles)
  const bundledValidation = await validate(bundledDocument)
  const errors = uniqueValidationErrors(validation.errors ?? [], bundledValidation.errors ?? [])
  const document = files[0].specification
  const summaryDocument = bundledValidation.schema ?? validation.schema ?? bundledDocument
  const summary = operationSummary(summaryDocument)
  const specificationVersion = typeof document.openapi === 'string'
    ? document.openapi
    : typeof document.swagger === 'string'
      ? document.swagger
      : ''
  return {
    scalarContent: bundledDocument,
    response: {
      reference: {
        title: typeof document.info?.title === 'string' ? document.info.title : 'OpenAPI',
        apiVersion: typeof document.info?.version === 'string' ? document.info.version : '',
        specificationVersion,
        valid: validation.valid === true && bundledValidation.valid === true,
        serverCount: Array.isArray(document.servers) ? document.servers.length : 0,
        pathCount: summary.pathCount,
        operations: summary.operations,
        tags: summary.tags,
        document: bundledDocument,
        externalDocuments: parsedFiles.slice(1).map((parsed) => ({
          id: parsed.file.filename,
          document: parsed.rawSpecification,
        })),
      },
      diagnostics: [
        ...parsedFiles.flatMap((parsed) => parsed.sourceMap.warnings),
        ...validationDiagnostics(errors, parsedFiles[0].sourceMap),
      ],
    },
  }
}

async function handleRequest(request) {
  switch (request.operation) {
    case 'renderMermaid':
      return renderMermaid(request.source, request.theme)
    case 'renderPlantUml':
      return renderPlantUml(request.source, request.theme)
    case 'inspectOpenApi': {
      try {
        const sourceMap = createSourceMap('document.openapi', request.source, true)
        const specification = normalize(request.source)
        return {
          references: specification && typeof specification === 'object'
            ? collectSourceReferences(specification, sourceMap)
            : [],
        }
      } catch {
        return { references: [] }
      }
    }
    case 'parseOpenApi':
      try {
        return (await prepareOpenApi(request)).response
      } catch (error) {
        return {
          code: 'visualization.invalidOpenApi',
          message: String(error?.message ?? error ?? 'The OpenAPI document could not be parsed.'),
          diagnostics: Array.isArray(error?.diagnostics)
            ? error.diagnostics
            : [diagnostic(error, 'visualization.invalidOpenApi')],
        }
      }
    case 'rasterizeSvg': {
      const pixelWidth = Math.ceil(Number(request.width) * Number(request.scale))
      const pixelHeight = Math.ceil(Number(request.height) * Number(request.scale))
      if (!Number.isFinite(pixelWidth) || !Number.isFinite(pixelHeight) || pixelWidth < 1 || pixelHeight < 1 || pixelWidth > 8192 || pixelHeight > 8192 || pixelWidth * pixelHeight > 64_000_000) {
        throw new Error('Raster dimensions exceed the WebKit limit.')
      }
      const root = document.getElementById('raster-root')
      root.replaceChildren()
      root.style.width = `${pixelWidth}px`
      root.style.height = `${pixelHeight}px`
      root.innerHTML = request.svg
      const svg = root.querySelector('svg')
      if (!svg) throw new Error('Raster input is not SVG.')
      svg.setAttribute('width', String(pixelWidth))
      svg.setAttribute('height', String(pixelHeight))
      svg.style.width = `${pixelWidth}px`
      svg.style.height = `${pixelHeight}px`
      await new Promise((resolve) => requestAnimationFrame(() => requestAnimationFrame(resolve)))
      return { rasterReady: true, pixelWidth, pixelHeight }
    }
    default:
      throw new Error('Unknown visualization operation.')
  }
}

let renderQueue = Promise.resolve()
window.busymarkRender = (request) => {
  const task = renderQueue.then(() => handleRequest(request))
  renderQueue = task.catch(() => undefined)
  return task
}
window.dispatchEvent(new Event('busymark-render-ready'))
