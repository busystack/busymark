// BusyMark owns mathematical document rendering through its semantic MathJax
// path. Mermaid's optional dollar-label renderer is deliberately unavailable,
// which prevents Mermaid's transitive alternate math engine from entering the
// offline runtime bundle.
export default Object.freeze({
  renderToString() {
    throw new Error('Math labels inside Mermaid diagrams are not supported.')
  },
})
