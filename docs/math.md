# Mathematical expressions

BusyMark renders mathematical expressions with its bundled MathJax 4 engine.
Rendering is local and works without an Internet connection in the preview,
Editor view, and Markdown PDF export. BusyMark supports TeX expressions inside
Markdown; it is not a complete TeX or LaTeX document compiler.

## Supported source forms

Normal Markdown and Writerside Markdown support inline dollar math:

```markdown
Euler's identity is $e^{i\pi}+1=0$.
```

GitHub's dollar/backtick form is supported when the expression needs to contain
Markdown-sensitive characters:

```markdown
The value is $`\sqrt{x^2+y^2}`$.
```

Display math can use double dollars or a `math` fence:

````markdown
$$
\int_0^1 x^2\,dx = \frac{1}{3}
$$

```math
\begin{aligned}
a &= b + c \\
d &= e + f
\end{aligned}
```
````

Writerside Markdown additionally treats a `tex` fence as display math and
supports inline semantic markup:

````markdown
```tex
\ce{2H2 + O2 -> 2H2O}
```

The domain is <math>\mathbb{R}</math>.
````

The same `<math>` element is recognized in Writerside XML `.topic` files.
Outside Writerside mode, a `tex` fence remains an ordinary code block.
BusyMark does not add `\(...\)` or `\[...\]` as Markdown delimiters.

## Scientific TeX profile

The pinned profile contains MathJax's base TeX support plus AMS mathematics,
`newcommand`, `mathtools`, `mhchem`, `boldsymbol`, `braket`, `cancel`, `cases`,
`empheq`, `gensymb`, `units`, and `upgreek`. A command declared with
`newcommand` applies only inside that expression; formulas do not share mutable
TeX state.

BusyMark deliberately does not enable `physics`, because that extension
redefines standard commands. Dynamic package loading and HTML-oriented
extensions—including `autoload`, `require`, `setoptions`, and `texhtml`—are
disabled. A document cannot request another MathJax package or remote font.

## Editing and export

An unfocused Editor-view block shows rendered math. Activating a block that
contains inline math switches that block to its exact Markdown source, including
the delimiters. Leaving the block reparses it and restores rendered math. This
keeps equation source available for selection, copy, undo, and normal text
editing without representing equations as hidden replacement characters.

Inline equations use MathJax's returned depth to align with the surrounding
text baseline. Display equations are centered; equations wider than the
preview remain available through horizontal scrolling. Invalid expressions
stay visible as source instead of removing the surrounding content.

Markdown PDF export uses the same MathJax package and font profile. BusyMark
stages sanitized, self-contained SVG equations for Typst, including inline
baseline metadata, so safe equations remain vector content in the PDF.

## Offline and security behavior

BusyMark ships MathJax 4.1.3 and New Computer Modern 4.1.3 as a deterministic
browser bundle. NewCM's dynamic glyph tables are bundled as well; uncommon,
calligraphic, and double-struck glyphs do not trigger downloads. The reusable
WebKit renderer has no network connectivity, uses a restrictive content security
policy, accepts only fixed packaged resources and operations, limits expression
and batch sizes and render time, applies MathJax safe processing, and passes
every SVG through BusyMark's generated-SVG normalizer before display or export.
