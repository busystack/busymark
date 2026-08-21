window.busymarkScriptErrors = []

function createMemoryStorage() {
  const values = new Map()
  return {
    get length() {
      return values.size
    },
    clear() {
      values.clear()
    },
    getItem(key) {
      const value = values.get(String(key))
      return value === undefined ? null : value
    },
    key(index) {
      return [...values.keys()][index] ?? null
    },
    removeItem(key) {
      values.delete(String(key))
    },
    setItem(key, value) {
      values.set(String(key), String(value))
    },
  }
}

// WebKit persistent storage is disabled by the host. Scalar expects the
// Storage interface to exist, so provide process-memory-only implementations.
if (typeof window.localStorage === 'undefined') {
  Object.defineProperty(window, 'localStorage', { value: createMemoryStorage() })
}
if (typeof window.sessionStorage === 'undefined') {
  Object.defineProperty(window, 'sessionStorage', { value: createMemoryStorage() })
}

window.addEventListener('error', (event) => {
  window.busymarkScriptErrors.push({
    message: String(event.message || 'JavaScript error'),
    source: String(event.filename || ''),
    line: Number(event.lineno || 0),
    column: Number(event.colno || 0),
  })
})

window.addEventListener('unhandledrejection', (event) => {
  window.busymarkScriptErrors.push({
    message: String(event.reason?.message ?? event.reason ?? 'Unhandled promise rejection'),
    source: '',
    line: 0,
    column: 0,
  })
})
