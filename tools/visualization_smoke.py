#!/usr/bin/python3

import argparse
import json
import os
import re
import subprocess
import sys
import tempfile
import xml.etree.ElementTree as et
from pathlib import Path

import gi

gi.require_foreign("cairo")
gi.require_version("Gtk", "3.0")
gi.require_version("WebKit2", "4.1")
from gi.repository import Gio, GLib, Gtk, WebKit2  # noqa: E402


def fenced_sources(path: Path, languages: tuple[str, ...]) -> list[str]:
    language_pattern = "|".join(re.escape(language) for language in languages)
    pattern = re.compile(
        rf"^```(?:{language_pattern})[^\n]*\n(.*?)^```\s*$",
        re.MULTILINE | re.DOTALL | re.IGNORECASE,
    )
    return pattern.findall(path.read_text(encoding="utf-8"))


class WebHarnessSmoke:
    def __init__(self, assets: Path, cases: list[dict[str, object]]) -> None:
        self.assets = assets
        self.cases = cases
        self.index = 0
        self.failures: list[str] = []
        self.loaded_uri: str | None = None
        self.recovery_pending = False
        self.recovery_completed = False
        self.loop = GLib.MainLoop()
        self.context = WebKit2.WebContext.new_ephemeral()
        self.context.set_sandbox_enabled("SNAP" not in os.environ)
        self.context.register_uri_scheme("busymark-render", self._serve)
        security_manager = self.context.get_security_manager()
        security_manager.register_uri_scheme_as_secure("busymark-render")
        security_manager.register_uri_scheme_as_cors_enabled("busymark-render")
        self.view = self._create_view()
        self.window = Gtk.OffscreenWindow()
        self.window.set_default_size(1280, 800)
        self.window.add(self.view)
        self.window.show_all()

    def _create_view(self) -> WebKit2.WebView:
        view = WebKit2.WebView.new_with_context(self.context)
        settings = WebKit2.Settings()
        settings.set_enable_javascript(True)
        settings.set_enable_html5_local_storage(False)
        settings.set_enable_html5_database(False)
        settings.set_javascript_can_open_windows_automatically(False)
        settings.set_enable_developer_extras(False)
        settings.set_enable_page_cache(False)
        settings.set_enable_media(False)
        settings.set_enable_webrtc(False)
        view.set_settings(settings)
        view.connect("load-changed", self._loaded)
        view.connect("load-failed", self._load_failed)
        view.connect("web-process-terminated", self._web_process_terminated)
        return view

    def _serve(self, request: WebKit2.URISchemeRequest) -> None:
        name = request.get_path().lstrip("/")
        allowed = {
            "harness.html",
            "reference.html",
            "bootstrap.js",
            "render-engines.js",
            "reference.js",
            "scalar.js",
            "viz-global.js",
        }
        if name not in allowed:
            request.finish_error(GLib.Error("Resource denied"))
            return
        path = self.assets / name
        data = path.read_bytes()
        mime = "text/html" if name.endswith(".html") else "text/javascript"
        stream = Gio.MemoryInputStream.new_from_bytes(GLib.Bytes.new(data))
        request.finish(stream, len(data), mime)

    def run(self) -> list[str]:
        GLib.timeout_add_seconds(180, self._timeout)
        self._start_case()
        self.loop.run()
        self.window.destroy()
        return self.failures

    def _timeout(self) -> bool:
        self.failures.append("WebKit visualization smoke test timed out")
        self.loop.quit()
        return GLib.SOURCE_REMOVE

    def _start_case(self) -> None:
        if self.index >= len(self.cases):
            self.loop.quit()
            return
        case = self.cases[self.index]
        target = str(case["uri"])
        if self.loaded_uri != target:
            self.loaded_uri = target
            self.view.load_uri(target)
        else:
            self._execute_case()

    def _loaded(self, _view: WebKit2.WebView, event: WebKit2.LoadEvent) -> None:
        if event == WebKit2.LoadEvent.FINISHED:
            self._execute_case()

    def _load_failed(
        self,
        _view: WebKit2.WebView,
        _event: WebKit2.LoadEvent,
        uri: str,
        error: GLib.Error,
    ) -> bool:
        self.failures.append(f"Failed to load {uri}: {error.message}")
        self.loop.quit()
        return True

    def _web_process_terminated(
        self, view: WebKit2.WebView, _reason: WebKit2.WebProcessTerminationReason
    ) -> None:
        if not self.recovery_pending:
            self.failures.append("WebKit web process terminated unexpectedly")
        else:
            print("PASS WebKit process termination and recovery")
        self.recovery_pending = False
        self.recovery_completed = True
        self.loaded_uri = None
        self.window.remove(view)
        view.destroy()
        self.view = self._create_view()
        self.window.add(self.view)
        self.window.show_all()
        GLib.idle_add(self._resume_after_recovery)

    def _resume_after_recovery(self) -> bool:
        self._start_case()
        return GLib.SOURCE_REMOVE

    def _execute_case(self) -> None:
        case = self.cases[self.index]
        payload = json.dumps(json.dumps(case["request"]))
        if case["uri"].endswith("reference.html"):
            function = "busymarkOpenReference"
            event = "busymark-reference-ready"
        else:
            function = "busymarkRender"
            event = "busymark-render-ready"
        body = f"""
if (typeof window.{function} !== 'function') {{
  await new Promise((resolve, reject) => {{
    const timer = setTimeout(() => reject(new Error('Harness readiness timeout')), 30000)
    addEventListener('{event}', () => {{ clearTimeout(timer); resolve() }}, {{ once: true }})
  }})
}}
return JSON.stringify(await window.{function}(JSON.parse({payload})))
"""
        self.view.call_async_javascript_function(
            body,
            -1,
            None,
            None,
            str(case["uri"]),
            None,
            self._finished,
            None,
        )

    def _finished(self, view: WebKit2.WebView, result: Gio.AsyncResult, _data) -> None:
        case = self.cases[self.index]
        try:
            value = view.call_async_javascript_function_finish(result)
            response = json.loads(value.to_string())
            validator = case["validator"]
            validator(response)
            if case.get("snapshot") is True:
                view.get_snapshot(
                    WebKit2.SnapshotRegion.FULL_DOCUMENT,
                    WebKit2.SnapshotOptions.TRANSPARENT_BACKGROUND,
                    None,
                    self._snapshot_finished,
                    None,
                )
                return
            print(f"PASS {case['name']}")
        except Exception as error:  # noqa: BLE001
            self.failures.append(f"{case['name']}: {error}")
        self._advance_case()

    def _snapshot_finished(
        self, view: WebKit2.WebView, result: Gio.AsyncResult, _data
    ) -> None:
        case = self.cases[self.index]
        try:
            surface = view.get_snapshot_finish(result)
            surface.flush()
            pixels = bytes(surface.get_data())
            opaque_pixels = sum(
                1 for index in range(3, len(pixels), 4) if pixels[index] != 0
            )
            colors = {
                pixels[index : index + 3]
                for index in range(0, len(pixels) - 3, 4)
                if pixels[index + 3] != 0
            }
            if surface.get_width() < 1200 or surface.get_height() < 800:
                raise AssertionError(
                    f"Raster snapshot was too small: {surface.get_width()}x{surface.get_height()}"
                )
            if opaque_pixels < 1000 or len(colors) < 8:
                raise AssertionError(
                    f"Raster snapshot was visually empty: {opaque_pixels} pixels, {len(colors)} colors"
                )
            print(f"PASS {case['name']} visual snapshot")
        except Exception as error:  # noqa: BLE001
            self.failures.append(f"{case['name']} visual snapshot: {error}")
        self._advance_case()

    def _advance_case(self) -> None:
        self.index += 1
        if self.index == 2 and not self.recovery_completed:
            self.recovery_pending = True
            self.view.terminate_web_process()
            return
        self._start_case()


def expect_svg(response: dict[str, object]) -> None:
    svg = response.get("svg")
    if not isinstance(svg, str) or "<svg" not in svg:
        raise AssertionError(response.get("message", "SVG was not returned"))


def expect_math_all_svg(response: dict[str, object]) -> None:
    if response.get("mathJaxVersion") != "4.1.3":
        raise AssertionError(f"Unexpected MathJax version: {response}")
    if response.get("fontVersion") != "4.1.3":
        raise AssertionError(f"Unexpected MathJax font version: {response}")
    results = response.get("results")
    if not isinstance(results, list) or not results:
        raise AssertionError(f"MathJax returned no results: {response}")
    for item in results:
        if not isinstance(item, dict) or not isinstance(item.get("svg"), str):
            raise AssertionError(f"MathJax did not return SVG: {item}")
        if "<svg" not in item["svg"] or "<defs" not in item["svg"]:
            raise AssertionError(f"MathJax SVG was not standalone: {item}")


def expect_math_partial_failure(response: dict[str, object]) -> None:
    results = response.get("results")
    if not isinstance(results, list) or len(results) != 2:
        raise AssertionError(f"Unexpected math batch: {response}")
    if not isinstance(results[0], dict) or "<svg" not in results[0].get("svg", ""):
        raise AssertionError(f"Valid expression did not render: {results[0]}")
    if (
        not isinstance(results[1], dict)
        or not isinstance(results[1].get("error"), dict)
        or results[1]["error"].get("code") != "math.invalidTex"
    ):
        raise AssertionError(f"Invalid expression did not fail locally: {results[1]}")


def expect_math_error(response: dict[str, object]) -> None:
    results = response.get("results")
    if not isinstance(results, list) or len(results) != 1:
        raise AssertionError(f"Unexpected math error batch: {response}")
    error = results[0].get("error") if isinstance(results[0], dict) else None
    if not isinstance(error, dict) or error.get("code") != "math.invalidTex":
        raise AssertionError(f"Expression unexpectedly inherited TeX state: {response}")


def expect_math_rejected(response: dict[str, object]) -> None:
    results = response.get("results")
    if not isinstance(results, list) or len(results) != 4:
        raise AssertionError(f"Unexpected unsafe-math batch: {response}")
    for item in results:
        error = item.get("error") if isinstance(item, dict) else None
        if not isinstance(error, dict) or error.get("code") not in {
            "math.invalidTex",
            "math.resourceLimit",
        }:
            raise AssertionError(f"Unsafe TeX was not rejected: {item}")


def expect_openapi(response: dict[str, object]) -> None:
    reference = response.get("reference")
    if not isinstance(reference, dict) or not reference.get("valid"):
        raise AssertionError(
            response.get("message", f"OpenAPI was not valid: {json.dumps(response)}")
        )
    if not reference.get("operations"):
        raise AssertionError("OpenAPI operation summary was empty")


def expect_openapi_diagnostic(response: dict[str, object]) -> None:
    reference = response.get("reference")
    diagnostics = response.get("diagnostics")
    if not isinstance(reference, dict) or reference.get("valid") is not False:
        raise AssertionError("Invalid OpenAPI document was reported as valid")
    if not isinstance(diagnostics, list) or not diagnostics:
        raise AssertionError("OpenAPI validation diagnostics were empty")
    if not any(item.get("line") == 7 for item in diagnostics if isinstance(item, dict)):
        raise AssertionError(f"OpenAPI diagnostic had no source line: {diagnostics}")


def expect_openapi_parse_diagnostic(response: dict[str, object]) -> None:
    diagnostics = response.get("diagnostics")
    if response.get("reference") is not None:
        raise AssertionError("Malformed OpenAPI source returned a reference")
    if not isinstance(diagnostics, list) or not diagnostics:
        raise AssertionError("OpenAPI parse diagnostics were empty")
    first = diagnostics[0]
    if (
        not isinstance(first, dict)
        or not isinstance(first.get("line"), int)
        or first["line"] < 1
    ):
        raise AssertionError(f"OpenAPI parse diagnostic had no source line: {diagnostics}")


def expect_openapi_dependency_diagnostic(response: dict[str, object]) -> None:
    diagnostics = response.get("diagnostics")
    if not isinstance(diagnostics, list) or not diagnostics:
        raise AssertionError("OpenAPI dependency diagnostics were empty")
    if not any(
        isinstance(item, dict)
        and item.get("sourceId") == "dependency-path.yaml"
        and item.get("sourceLine") == 4
        and item.get("line") is None
        for item in diagnostics
    ):
        raise AssertionError(
            f"OpenAPI dependency diagnostic used the wrong source map: {diagnostics}"
        )


def expect_local_references(response: dict[str, object]) -> None:
    references = response.get("references")
    if not isinstance(references, list) or len(references) != 1:
        raise AssertionError(f"Unexpected OpenAPI references: {references}")
    reference = references[0]
    if (
        not isinstance(reference, dict)
        or reference.get("value") != "./openapi/components.yaml"
        or not isinstance(reference.get("line"), int)
    ):
        raise AssertionError(f"Unexpected OpenAPI reference: {reference}")


def expect_reference(response: dict[str, object]) -> None:
    if response.get("opened") is not True:
        raise AssertionError("Scalar API Reference did not open")


def expect_raster_ready(response: dict[str, object]) -> None:
    if response.get("rasterReady") is not True:
        raise AssertionError(f"WebKit did not prepare the raster image: {response}")
    if response.get("pixelWidth") != 1200 or response.get("pixelHeight") != 800:
        raise AssertionError(f"Unexpected raster dimensions: {response}")
    if (
        response.get("renderedWidth") != 1200
        or response.get("renderedHeight") != 800
    ):
        raise AssertionError(f"SVG did not fill the raster canvas: {response}")


def d2_smoke(executable: Path) -> tuple[list[str], dict[str, str]]:
    failures: list[str] = []
    outputs: dict[str, str] = {}
    sources = {
        "D2 vector": "direction: right\na -> b\n",
        "D2 foreignObject": (
            "source: |md\n"
            "  # Markdown label\n"
            "  **Offline** rendering\n"
            "|\n"
            "source -> output\n"
        ),
    }
    for name, source in sources.items():
        with tempfile.TemporaryDirectory(prefix="busymark-d2-smoke-") as directory:
            result = subprocess.run(
                [
                    str(executable),
                    "--layout",
                    "dagre",
                    "--theme",
                    "0",
                    "--dark-theme",
                    "0",
                    "--pad",
                    "24",
                    "--timeout",
                    "10",
                    "--bundle=false",
                    "--omit-version",
                    "--no-xml-tag",
                    "-",
                    "-",
                ],
                input=source.encode(),
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                cwd=directory,
                env={"LANG": "C.UTF-8", "LC_ALL": "C.UTF-8"},
                timeout=15,
                check=False,
            )
        try:
            if result.returncode != 0:
                raise AssertionError(result.stderr.decode(errors="replace"))
            root = et.fromstring(result.stdout)
            if not root.tag.endswith("svg"):
                raise AssertionError("D2 output root is not SVG")
            if name.endswith("foreignObject") and b"foreignObject" not in result.stdout:
                raise AssertionError("D2 Markdown output did not contain foreignObject")
            outputs[name] = result.stdout.decode()
            print(f"PASS {name}")
        except Exception as error:  # noqa: BLE001
            failures.append(f"{name}: {error}")
    return failures, outputs


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--assets", required=True, type=Path)
    parser.add_argument("--d2", required=True, type=Path)
    parser.add_argument(
        "--demo", default=Path("demo/visualizations.md"), type=Path
    )
    parser.add_argument(
        "--plantuml-corpus",
        default=Path("demo/plantuml-conformance.md"),
        type=Path,
    )
    args = parser.parse_args()

    mermaid = fenced_sources(args.demo, ("mermaid",))[0]
    openapi = fenced_sources(args.demo, ("openapi", "oas", "swagger"))[0]
    local_openapi = fenced_sources(
        Path("demo/openapi-local-reference.md"), ("openapi", "oas", "swagger")
    )[0]
    local_dependency = Path("demo/openapi/components.yaml").read_text(
        encoding="utf-8"
    )
    plantuml = fenced_sources(args.plantuml_corpus, ("plantuml", "puml"))
    d2_failures, d2_outputs = d2_smoke(args.d2.resolve())
    cases: list[dict[str, object]] = [
        {
            "name": "Mermaid",
            "uri": "busymark-render://app/harness.html",
            "request": {
                "operation": "renderMermaid",
                "source": mermaid,
                "theme": "light",
            },
            "validator": expect_svg,
        },
        {
            "name": "Mermaid dark theme",
            "uri": "busymark-render://app/harness.html",
            "request": {
                "operation": "renderMermaid",
                "source": mermaid,
                "theme": "dark",
            },
            "validator": expect_svg,
        },
        {
            "name": "MathJax NewCM double-struck",
            "uri": "busymark-render://app/harness.html",
            "request": {
                "operation": "renderMathBatch",
                "expressions": [
                    {
                        "id": "mathbb",
                        "expression": r"\mathbb{R}",
                        "display": False,
                        "em": 16,
                        "ex": 8,
                        "containerWidth": 720,
                        "svgIdPrefix": "smoke-mathbb",
                    }
                ],
            },
            "validator": expect_math_all_svg,
        },
        {
            "name": "MathJax NewCM sequential calligraphic",
            "uri": "busymark-render://app/harness.html",
            "request": {
                "operation": "renderMathBatch",
                "expressions": [
                    {
                        "id": "mathcal",
                        "expression": r"\mathcal{L}",
                        "display": False,
                        "em": 16,
                        "ex": 8,
                        "containerWidth": 720,
                        "svgIdPrefix": "smoke-mathcal",
                    }
                ],
            },
            "validator": expect_math_all_svg,
        },
        {
            "name": "MathJax scientific package profile",
            "uri": "busymark-render://app/harness.html",
            "request": {
                "operation": "renderMathBatch",
                "expressions": [
                    {
                        "id": "scientific",
                        "expression": (
                            r"\ce{2H2 + O2 -> 2H2O}\quad"
                            r"\Braket{\psi|\phi}+\cancel{x}+\upalpha"
                            r"+a\coloneqq b+\units{m}"
                        ),
                        "display": True,
                        "em": 16,
                        "ex": 8,
                        "containerWidth": 720,
                        "svgIdPrefix": "smoke-scientific",
                    },
                    {
                        "id": "boldsymbol",
                        "expression": r"\boldsymbol{\alpha}",
                        "display": False,
                        "em": 16,
                        "ex": 8,
                        "containerWidth": 720,
                        "svgIdPrefix": "smoke-boldsymbol",
                    },
                    {
                        "id": "cases",
                        "expression": r"f(x)=\begin{cases}x&x>0\\0&x\leq0\end{cases}",
                        "display": True,
                        "em": 16,
                        "ex": 8,
                        "containerWidth": 720,
                        "svgIdPrefix": "smoke-cases",
                    },
                    {
                        "id": "gensymb",
                        "expression": r"90\degree",
                        "display": False,
                        "em": 16,
                        "ex": 8,
                        "containerWidth": 720,
                        "svgIdPrefix": "smoke-gensymb",
                    },
                    {
                        "id": "empheq",
                        "expression": r"\begin{empheq}{align}E&=mc^2\end{empheq}",
                        "display": True,
                        "em": 16,
                        "ex": 8,
                        "containerWidth": 720,
                        "svgIdPrefix": "smoke-empheq",
                    },
                    {
                        "id": "ams",
                        "expression": r"\begin{align}a&=b\end{align}",
                        "display": True,
                        "em": 16,
                        "ex": 8,
                        "containerWidth": 720,
                        "svgIdPrefix": "smoke-ams",
                    },
                ],
            },
            "validator": expect_math_all_svg,
        },
        {
            "name": "MathJax partial failure",
            "uri": "busymark-render://app/harness.html",
            "request": {
                "operation": "renderMathBatch",
                "expressions": [
                    {
                        "id": "valid",
                        "expression": r"\sqrt{x^2+y^2}",
                        "display": False,
                        "em": 16,
                        "ex": 8,
                        "containerWidth": 720,
                        "svgIdPrefix": "smoke-valid",
                    },
                    {
                        "id": "invalid",
                        "expression": r"\frac{",
                        "display": False,
                        "em": 16,
                        "ex": 8,
                        "containerWidth": 720,
                        "svgIdPrefix": "smoke-invalid",
                    },
                ],
            },
            "validator": expect_math_partial_failure,
        },
        {
            "name": "MathJax unsafe and dynamic commands",
            "uri": "busymark-render://app/harness.html",
            "request": {
                "operation": "renderMathBatch",
                "expressions": [
                    {
                        "id": name,
                        "expression": expression,
                        "display": False,
                        "em": 16,
                        "ex": 8,
                        "containerWidth": 720,
                        "svgIdPrefix": f"smoke-{name}",
                    }
                    for name, expression in [
                        ("url", r"\href{javascript:alert(1)}{x}"),
                        ("dynamic", r"\require{physics}"),
                        ("style", r"\style{position:fixed}{x}"),
                        ("recursive", r"\newcommand{\loop}{\loop}\loop"),
                    ]
                ],
            },
            "validator": expect_math_rejected,
        },
        {
            "name": "MathJax local newcommand",
            "uri": "busymark-render://app/harness.html",
            "request": {
                "operation": "renderMathBatch",
                "expressions": [
                    {
                        "id": "macro-definition",
                        "expression": r"\newcommand{\busyisolated}{z}\busyisolated",
                        "display": False,
                        "em": 16,
                        "ex": 8,
                        "containerWidth": 720,
                        "svgIdPrefix": "smoke-macro-definition",
                    }
                ],
            },
            "validator": expect_math_all_svg,
        },
        {
            "name": "MathJax expression isolation",
            "uri": "busymark-render://app/harness.html",
            "request": {
                "operation": "renderMathBatch",
                "expressions": [
                    {
                        "id": "macro-isolation",
                        "expression": r"\busyisolated",
                        "display": False,
                        "em": 16,
                        "ex": 8,
                        "containerWidth": 720,
                        "svgIdPrefix": "smoke-macro-isolation",
                    }
                ],
            },
            "validator": expect_math_error,
        },
        *(
            [
                {
                    "name": "D2 WebKit raster fallback",
                    "uri": "busymark-render://app/harness.html",
                    "request": {
                        "operation": "rasterizeSvg",
                        "svg": d2_outputs["D2 foreignObject"],
                        "width": 600,
                        "height": 400,
                        "scale": 2,
                    },
                    "validator": expect_raster_ready,
                    "snapshot": True,
                }
            ]
            if "D2 foreignObject" in d2_outputs
            else []
        ),
        {
            "name": "Responsive SVG raster scaling",
            "uri": "busymark-render://app/harness.html",
            "request": {
                "operation": "rasterizeSvg",
                "svg": (
                    '<svg xmlns="http://www.w3.org/2000/svg" width="100%" '
                    'style="max-width:600px" viewBox="0 0 600 400">'
                    '<rect width="600" height="400" fill="#1a73e8"/></svg>'
                ),
                "width": 600,
                "height": 400,
                "scale": 2,
            },
            "validator": expect_raster_ready,
            "snapshot": True,
        },
        *[
            {
                "name": f"PlantUML {index + 1}/{len(plantuml)}",
                "uri": "busymark-render://app/harness.html",
                "request": {
                    "operation": "renderPlantUml",
                    "source": source,
                    "theme": "light",
                },
                "validator": expect_svg,
            }
            for index, source in enumerate(plantuml)
        ],
        {
            "name": "PlantUML dark theme",
            "uri": "busymark-render://app/harness.html",
            "request": {
                "operation": "renderPlantUml",
                "source": plantuml[0],
                "theme": "dark",
            },
            "validator": expect_svg,
        },
        {
            "name": "OpenAPI parser",
            "uri": "busymark-render://app/harness.html",
            "request": {
                "operation": "parseOpenApi",
                "entryId": "demo.openapi",
                "source": openapi,
                "dependencies": [],
            },
            "validator": expect_openapi,
        },
        {
            "name": "OpenAPI local reference inspection",
            "uri": "busymark-render://app/harness.html",
            "request": {
                "operation": "inspectOpenApi",
                "source": local_openapi,
            },
            "validator": expect_local_references,
        },
        {
            "name": "OpenAPI local circular reference",
            "uri": "busymark-render://app/harness.html",
            "request": {
                "operation": "parseOpenApi",
                "entryId": "demo/openapi-local-reference.md",
                "source": local_openapi,
                "dependencies": [
                    {
                        "id": "demo/openapi/components.yaml",
                        "source": local_dependency,
                    }
                ],
            },
            "validator": expect_openapi,
        },
        {
            "name": "OpenAPI validation source location",
            "uri": "busymark-render://app/harness.html",
            "request": {
                "operation": "parseOpenApi",
                "entryId": "invalid.openapi",
                "source": (
                    "openapi: 3.1.0\n"
                    "info:\n"
                    "  title: Invalid\n"
                    "paths:\n"
                    "  /pets:\n"
                    "    get:\n"
                    "      responses: []\n"
                ),
                "dependencies": [],
            },
            "validator": expect_openapi_diagnostic,
        },
        {
            "name": "OpenAPI parse source location",
            "uri": "busymark-render://app/harness.html",
            "request": {
                "operation": "parseOpenApi",
                "entryId": "malformed.openapi",
                "source": "openapi: [3.1.0\n",
                "dependencies": [],
            },
            "validator": expect_openapi_parse_diagnostic,
        },
        {
            "name": "OpenAPI dependency source location",
            "uri": "busymark-render://app/harness.html",
            "request": {
                "operation": "parseOpenApi",
                "entryId": "dependency-entry.openapi",
                "source": (
                    "openapi: 3.1.0\n"
                    "info:\n"
                    "  title: Dependency diagnostic\n"
                    "  version: 1.0.0\n"
                    "paths:\n"
                    "  /pets/{id}:\n"
                    "    $ref: './dependency-path.yaml#/path'\n"
                ),
                "dependencies": [
                    {
                        "id": "dependency-path.yaml",
                        "source": (
                            "path:\n"
                            "  get:\n"
                            "    parameters:\n"
                            "      - name: other\n"
                            "        in: path\n"
                            "        required: true\n"
                            "        schema:\n"
                            "          type: string\n"
                            "    responses:\n"
                            "      '200':\n"
                            "        description: OK\n"
                        ),
                    }
                ],
            },
            "validator": expect_openapi_dependency_diagnostic,
        },
        {
            "name": "Scalar API Reference",
            "uri": "busymark-render://app/reference.html",
            "request": {
                "entryId": "demo.openapi",
                "source": openapi,
                "dependencies": [],
                "theme": "light",
            },
            "validator": expect_reference,
        },
        {
            "name": "Scalar local circular reference",
            "uri": "busymark-render://app/reference.html",
            "request": {
                "entryId": "demo/openapi-local-reference.md",
                "source": local_openapi,
                "dependencies": [
                    {
                        "id": "demo/openapi/components.yaml",
                        "source": local_dependency,
                    }
                ],
                "theme": "dark",
            },
            "validator": expect_reference,
        },
    ]
    failures = WebHarnessSmoke(args.assets.resolve(), cases).run()
    failures.extend(d2_failures)
    if failures:
        for failure in failures:
            print(f"FAIL {failure}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
