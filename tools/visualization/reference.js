let scalarInstance
let rendererLoad

function showReferenceError(error) {
  const root = document.getElementById('app')
  const panel = document.createElement('section')
  panel.setAttribute('role', 'alert')
  panel.style.cssText = 'max-width:52rem;margin:4rem auto;padding:1.5rem;border:1px solid #b91c1c;border-radius:.75rem;font:16px/1.5 sans-serif'
  const heading = document.createElement('h1')
  heading.textContent = 'API Reference could not be opened'
  const message = document.createElement('p')
  message.textContent = String(error?.message ?? error ?? 'Unknown error')
  panel.append(heading, message)
  root?.replaceChildren(panel)
}

function loadRenderer() {
  rendererLoad ??= import('./render-engines.js')
  return rendererLoad
}

window.busymarkOpenReference = async (request) => {
  try {
    const { prepareOpenApi } = await loadRenderer()
    const prepared = await prepareOpenApi(request)
    if (!prepared.response.reference) {
      throw new Error(prepared.response.message ?? 'The OpenAPI document could not be parsed.')
    }
    if (typeof window.Scalar?.createApiReference !== 'function') {
      const details = JSON.stringify(window.busymarkScriptErrors ?? [])
      throw new Error(`Scalar API Reference failed to initialize: ${details}`)
    }
    scalarInstance?.destroy?.()
    document.documentElement.dataset.theme = request.theme === 'dark' ? 'dark' : 'light'
    scalarInstance = window.Scalar.createApiReference('#app', {
      content: prepared.scalarContent,
      agent: { disabled: true },
      telemetry: false,
      persistAuth: false,
      hideTestRequestButton: true,
      hideClientButton: true,
      showDeveloperTools: 'never',
      documentDownloadType: 'none',
      withDefaultFonts: false,
      pluginUrls: [],
      mcp: { disabled: true },
      darkMode: request.theme === 'dark',
      forceDarkModeState: request.theme === 'dark' ? 'dark' : 'light',
      hideDarkModeToggle: true,
      customFetch: async () => {
        throw new Error('Network access is disabled in BusyMark API Reference.')
      },
    })
    return { opened: true }
  } catch (error) {
    showReferenceError(error)
    throw error
  }
}
window.dispatchEvent(new Event('busymark-reference-ready'))
