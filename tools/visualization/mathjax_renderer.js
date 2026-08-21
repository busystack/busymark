import { mathjax } from '@mathjax/src/js/mathjax.js'
import { browserAdaptor } from '@mathjax/src/js/adaptors/browserAdaptor.js'
import { RegisterHTMLHandler } from '@mathjax/src/js/handlers/html.js'
import { TeX } from '@mathjax/src/js/input/tex.js'
import { MapHandler } from '@mathjax/src/js/input/tex/MapHandler.js'
import { NewcommandTables } from '@mathjax/src/js/input/tex/newcommand/NewcommandUtil.js'
import { SVG } from '@mathjax/src/js/output/svg.js'
import { SafeHandler } from '@mathjax/src/js/ui/safe/SafeHandler.js'
import { MathJaxNewcmFont } from '@mathjax/mathjax-newcm-font/js/svg.js'

import '@mathjax/src/js/input/tex/ams/AmsConfiguration.js'
import '@mathjax/src/js/input/tex/newcommand/NewcommandConfiguration.js'
import '@mathjax/src/js/input/tex/mathtools/MathtoolsConfiguration.js'
import '@mathjax/src/js/input/tex/mhchem/MhchemConfiguration.js'
import '@mathjax/src/js/input/tex/boldsymbol/BoldsymbolConfiguration.js'
import '@mathjax/src/js/input/tex/braket/BraketConfiguration.js'
import '@mathjax/src/js/input/tex/cancel/CancelConfiguration.js'
import '@mathjax/src/js/input/tex/cases/CasesConfiguration.js'
import '@mathjax/src/js/input/tex/empheq/EmpheqConfiguration.js'
import '@mathjax/src/js/input/tex/gensymb/GensymbConfiguration.js'
import '@mathjax/src/js/input/tex/units/UnitsConfiguration.js'
import '@mathjax/src/js/input/tex/upgreek/UpgreekConfiguration.js'

// NewCM's dynamic SVG tables are all statically included in BusyMark's one
// deterministic bundle. MathJax still uses its asynchronous retry path, but
// the loader below only activates already-bundled table registrations.
import '@mathjax/mathjax-newcm-font/js/svg/dynamic/PUA.js'
import '@mathjax/mathjax-newcm-font/js/svg/dynamic/accents-b-i.js'
import '@mathjax/mathjax-newcm-font/js/svg/dynamic/accents.js'
import '@mathjax/mathjax-newcm-font/js/svg/dynamic/arabic.js'
import '@mathjax/mathjax-newcm-font/js/svg/dynamic/arrows.js'
import '@mathjax/mathjax-newcm-font/js/svg/dynamic/braille-d.js'
import '@mathjax/mathjax-newcm-font/js/svg/dynamic/braille.js'
import '@mathjax/mathjax-newcm-font/js/svg/dynamic/calligraphic.js'
import '@mathjax/mathjax-newcm-font/js/svg/dynamic/cherokee.js'
import '@mathjax/mathjax-newcm-font/js/svg/dynamic/cyrillic-ss.js'
import '@mathjax/mathjax-newcm-font/js/svg/dynamic/cyrillic.js'
import '@mathjax/mathjax-newcm-font/js/svg/dynamic/devanagari.js'
import '@mathjax/mathjax-newcm-font/js/svg/dynamic/double-struck.js'
import '@mathjax/mathjax-newcm-font/js/svg/dynamic/fraktur.js'
import '@mathjax/mathjax-newcm-font/js/svg/dynamic/greek-ss.js'
import '@mathjax/mathjax-newcm-font/js/svg/dynamic/greek.js'
import '@mathjax/mathjax-newcm-font/js/svg/dynamic/hebrew.js'
import '@mathjax/mathjax-newcm-font/js/svg/dynamic/latin-b.js'
import '@mathjax/mathjax-newcm-font/js/svg/dynamic/latin-bi.js'
import '@mathjax/mathjax-newcm-font/js/svg/dynamic/latin-i.js'
import '@mathjax/mathjax-newcm-font/js/svg/dynamic/latin.js'
import '@mathjax/mathjax-newcm-font/js/svg/dynamic/marrows.js'
import '@mathjax/mathjax-newcm-font/js/svg/dynamic/math.js'
import '@mathjax/mathjax-newcm-font/js/svg/dynamic/monospace-ex.js'
import '@mathjax/mathjax-newcm-font/js/svg/dynamic/monospace-l.js'
import '@mathjax/mathjax-newcm-font/js/svg/dynamic/monospace.js'
import '@mathjax/mathjax-newcm-font/js/svg/dynamic/mshapes.js'
import '@mathjax/mathjax-newcm-font/js/svg/dynamic/phonetics-ss.js'
import '@mathjax/mathjax-newcm-font/js/svg/dynamic/phonetics.js'
import '@mathjax/mathjax-newcm-font/js/svg/dynamic/sans-serif-b.js'
import '@mathjax/mathjax-newcm-font/js/svg/dynamic/sans-serif-bi.js'
import '@mathjax/mathjax-newcm-font/js/svg/dynamic/sans-serif-ex.js'
import '@mathjax/mathjax-newcm-font/js/svg/dynamic/sans-serif-i.js'
import '@mathjax/mathjax-newcm-font/js/svg/dynamic/sans-serif-r.js'
import '@mathjax/mathjax-newcm-font/js/svg/dynamic/sans-serif.js'
import '@mathjax/mathjax-newcm-font/js/svg/dynamic/script.js'
import '@mathjax/mathjax-newcm-font/js/svg/dynamic/shapes.js'
import '@mathjax/mathjax-newcm-font/js/svg/dynamic/symbols-b-i.js'
import '@mathjax/mathjax-newcm-font/js/svg/dynamic/symbols.js'
import '@mathjax/mathjax-newcm-font/js/svg/dynamic/variants.js'

export const mathJaxVersion = '4.1.3'
export const mathJaxFontVersion = '4.1.3'
export const mathPackageProfileVersion = 'busymark-math-v1'

export const mathPackages = Object.freeze([
  'base',
  'ams',
  'newcommand',
  'mathtools',
  'mhchem',
  'boldsymbol',
  'braket',
  'cancel',
  'cases',
  'empheq',
  'gensymb',
  'units',
  'upgreek',
])

const maximumExpressionCharacters = 16 * 1024
const maximumBatchExpressions = 128
const maximumBatchCharacters = 256 * 1024
const maximumSvgBytes = 2 * 1024 * 1024

const adaptor = browserAdaptor()
const handler = RegisterHTMLHandler(adaptor)
SafeHandler(handler)

// Every dynamic font module above has already registered its setup callback.
// No URL or filesystem resolution is permitted from TeX input.
mathjax.asyncLoad = () => Promise.resolve()

const tex = new TeX({
  packages: mathPackages,
  maxBuffer: 20 * 1024,
  maxMacros: 500,
  maxTemplateSubtitutions: 2000,
  formatError: (_jax, error) => { throw error },
})

const svg = new SVG({
  fontData: MathJaxNewcmFont,
  fontCache: 'local',
  localID: 'busymark-math',
  useXlink: false,
  displayOverflow: 'overflow',
  linebreaks: {
    inline: false,
    width: '100%',
    lineleading: 0.2,
  },
})

const mathDocument = mathjax.document('', {
  InputJax: tex,
  OutputJax: svg,
  safeOptions: {
    allow: {
      URLs: 'none',
      classes: 'none',
      cssIDs: 'none',
      styles: 'none',
    },
    safeProtocols: {
      http: false,
      https: false,
      file: false,
      javascript: false,
      data: false,
    },
  },
})

const mathReady = svg.font.loadDynamicFiles()

function clearExpressionDefinitions() {
  // The newcommand package intentionally stores definitions in three mutable
  // maps.  BusyMark supports declarations within an expression, but formulas
  // are independent document atoms: one expression must never provide macros
  // or environments to a later expression.  These maps are part of the exact,
  // pinned MathJax source API bundled above.
  for (const name of [
    NewcommandTables.NEW_DELIMITER,
    NewcommandTables.NEW_COMMAND,
    NewcommandTables.NEW_ENVIRONMENT,
  ]) {
    const map = MapHandler.getMap(name)
    map?.map?.clear()
  }
}

function finiteMetric(value, fallback, minimum, maximum) {
  const number = Number(value)
  return Number.isFinite(number)
    ? Math.min(maximum, Math.max(minimum, number))
    : fallback
}

function parseExLength(value, ex) {
  const match = String(value ?? '').trim().match(/^(-?(?:\d+(?:\.\d*)?|\.\d+))(ex|em|px)?$/)
  if (!match) return 0
  const number = Number.parseFloat(match[1])
  if (!Number.isFinite(number)) return 0
  if (match[2] === 'em') return number * ex * 2
  if (match[2] === 'px' || !match[2]) return number
  return number * ex
}

function mathError(error) {
  const detail = String(error?.message ?? error ?? 'Math rendering failed.').slice(0, 1000)
  const lowered = detail.toLowerCase()
  const resourceLimit = lowered.includes('maximum')
    || lowered.includes('maxbuffer')
    || lowered.includes('substitution')
    || lowered.includes('recursion')
    || lowered.includes('stack')
  return {
    code: resourceLimit ? 'math.resourceLimit' : 'math.invalidTex',
    message: resourceLimit
      ? 'The expression exceeded BusyMark’s math processing limits.'
      : 'The expression contains unsupported or invalid TeX.',
    detail,
  }
}

async function renderExpression(item) {
  const id = String(item?.id ?? '')
  const expression = String(item?.expression ?? '')
  if (!id || id.length > 128 || !/^[A-Za-z0-9_.:-]+$/.test(id)) {
    return { id, error: { code: 'math.invalidRequest', message: 'The expression identifier is invalid.' } }
  }
  if (!expression || expression.length > maximumExpressionCharacters) {
    return {
      id,
      error: {
        code: expression ? 'math.resourceLimit' : 'math.invalidTex',
        message: expression
          ? 'The expression exceeds BusyMark’s size limit.'
          : 'The expression is empty.',
      },
    }
  }

  const em = finiteMetric(item.em, 16, 4, 256)
  const ex = finiteMetric(item.ex, em / 2, 2, 128)
  const containerWidth = finiteMetric(item.containerWidth, 800, 32, 10000)
  const localID = String(item.svgIdPrefix ?? `busymark-math-${id}`)
    .replace(/[^A-Za-z0-9_.:-]/g, '-')
    .slice(0, 128)
  svg.options.localID = localID
  try {
    // convertPromise is the direct-document equivalent of tex2svgPromise and
    // handles MathJax's asynchronous NewCM retry protocol.
    const container = await mathDocument.convertPromise(expression, {
      display: item.display === true,
      em,
      ex,
      containerWidth,
    })
    const roots = adaptor.tags(container, 'svg')
    const root = roots[0]
    if (!root) throw new Error('MathJax did not return SVG output.')
    const width = parseExLength(adaptor.getAttribute(root, 'width'), ex)
    const height = parseExLength(adaptor.getAttribute(root, 'height'), ex)
    const verticalAlign = adaptor.getStyle(root, 'vertical-align')
    const depth = Math.max(0, -parseExLength(verticalAlign, ex))
    adaptor.setStyle(root, 'vertical-align', '')
    if (!adaptor.allStyles(root).trim()) adaptor.removeAttribute(root, 'style')
    const standaloneSvg = adaptor.outerHTML(root)
    if (new TextEncoder().encode(standaloneSvg).length > maximumSvgBytes) {
      return {
        id,
        error: { code: 'math.resourceLimit', message: 'The rendered expression exceeds BusyMark’s output limit.' },
      }
    }
    return {
      id,
      svg: standaloneSvg,
      width,
      height,
      depth,
      baseline: Math.max(0, height - depth),
    }
  } catch (error) {
    return { id, error: mathError(error) }
  } finally {
    // TeX.reset clears accumulated equation counters, labels, IDs, and parse
    // state.  Each Markdown math node is an independent render unit.
    tex.reset(0)
    clearExpressionDefinitions()
  }
}

export async function renderMathBatch(request) {
  const expressions = Array.isArray(request?.expressions) ? request.expressions : []
  if (expressions.length === 0 || expressions.length > maximumBatchExpressions) {
    return {
      code: 'math.resourceLimit',
      message: 'The math batch is empty or exceeds BusyMark’s expression limit.',
      results: [],
    }
  }
  const aggregate = expressions.reduce(
    (total, item) => total + String(item?.expression ?? '').length,
    0,
  )
  if (aggregate > maximumBatchCharacters) {
    return {
      code: 'math.resourceLimit',
      message: 'The math batch exceeds BusyMark’s aggregate input limit.',
      results: expressions.map((item) => ({
        id: String(item?.id ?? ''),
        error: { code: 'math.resourceLimit', message: 'The math batch is too large.' },
      })),
    }
  }

  await mathReady
  const results = []
  for (const expression of expressions) {
    results.push(await renderExpression(expression))
  }
  return {
    mathJaxVersion,
    fontVersion: mathJaxFontVersion,
    packageProfileVersion: mathPackageProfileVersion,
    results,
  }
}
