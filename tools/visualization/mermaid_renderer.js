import mermaid from 'mermaid'

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

export async function renderMermaid(source, theme) {
  mermaid.initialize({
    startOnLoad: false,
    securityLevel: 'strict',
    // Upstream renders flowchart math through MathML HTML labels. Ordinary
    // diagrams keep vector text; strict sanitization applies in both modes.
    htmlLabels: source.includes('$$'),
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
