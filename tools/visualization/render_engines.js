// Each fixed offline engine bundle is loaded only when its operation is used.
// Module imports share evaluation within the reusable view. Rasterization needs
// only this small harness; recovery starts with a fresh module registry.
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

async function loadEngine(load) {
  try {
    return await load()
  } catch {
    // WebKit caches failed module imports in the view's module registry. Tell
    // the native host to retire that registry before processing queued work.
    const error = new Error('The bundled visualization engine could not be loaded.')
    error.busymarkEngineLoadFailed = true
    throw error
  }
}

export async function prepareOpenApi(request) {
  return (await loadEngine(() => import('./openapi-engine.js'))).prepareOpenApi(request)
}

async function handleRequest(request) {
  switch (request.operation) {
    case 'renderMermaid':
      return (await loadEngine(() => import('./mermaid-engine.js'))).renderMermaid(request.source, request.theme)
    case 'renderPlantUml':
      return (await loadEngine(() => import('./plantuml-engine.js'))).renderPlantUml(request.source, request.theme)
    case 'renderMathBatch':
      return (await loadEngine(() => import('./math-engine.js'))).renderMathBatch(request)
    case 'inspectOpenApi':
      return (await loadEngine(() => import('./openapi-engine.js'))).inspectOpenApi(request.source)
    case 'parseOpenApi':
      try {
        return (await prepareOpenApi(request)).response
      } catch (error) {
        if (error?.busymarkEngineLoadFailed === true) throw error
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
      // Mermaid emits width="100%" together with an inline max-width equal to
      // its logical viewBox width. When the raster scale is greater than one,
      // that max-width otherwise keeps the drawing at logical size inside a
      // larger pixel canvas, producing a half-sized, left-aligned preview.
      // The raster canvas owns the outer geometry; the SVG viewBox continues
      // to preserve the diagram's aspect ratio.
      svg.style.setProperty('width', `${pixelWidth}px`, 'important')
      svg.style.setProperty('height', `${pixelHeight}px`, 'important')
      svg.style.setProperty('max-width', 'none', 'important')
      svg.style.setProperty('max-height', 'none', 'important')
      await new Promise((resolve) => requestAnimationFrame(() => requestAnimationFrame(resolve)))
      const renderedBounds = svg.getBoundingClientRect()
      return {
        rasterReady: true,
        pixelWidth,
        pixelHeight,
        renderedWidth: renderedBounds.width,
        renderedHeight: renderedBounds.height,
      }
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
