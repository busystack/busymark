import {
  render as renderPlantUmlIntoElement,
  renderToString as renderPlantUmlToString,
} from '@plantuml/core'

let renderSequence = 0

let graphvizLoad

function loadGraphviz() {
  graphvizLoad ??= new Promise((resolve, reject) => {
    const script = document.createElement('script')
    script.src = './viz-global.js'
    script.onload = () => resolve()
    script.onerror = () => {
      script.remove()
      graphvizLoad = undefined
      const error = new Error('The bundled Graphviz engine could not be loaded.')
      error.busymarkEngineLoadFailed = true
      reject(error)
    }
    document.head.append(script)
  })
  return graphvizLoad
}

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

export async function renderPlantUml(source, theme) {
  await loadGraphviz()
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
