# Keyboard view selection

F9 shows or hides the sidebar. Ctrl+Shift+F9 opens **Sidebar view** and reveals
the sidebar when hidden, including in a narrow window. Ctrl+Shift+F10 opens
**Content view**. These commands can be reassigned in Keyboard Shortcuts;
the buttons' tooltips and accessible names follow the effective keymap.

While a selector is open, press its displayed letter to activate a view.
Arrow keys and Enter also select a view; Escape dismisses the menu and returns
focus. Letters belong to the open menu and never enter the document.

| Sidebar letter | View |
| --- | --- |
| F | Files (Notes in a Notes workspace) |
| T | Table of Contents (Writerside) |
| O | Outline |
| C | Commit |
| G | Git Log |
| L | Local History |
| B | Clipboard History |
| R | References |

| Content letter | View |
| --- | --- |
| E | Editor |
| S | Source |
| R | Reading |
| D | Dual |

Dual retains the side-by-side Source and rendered document layout. Its stored
preference and command identity remain compatible with existing settings.

Unavailable sidebar views stay unavailable. For example, Table of Contents requires a
Writerside workspace, and Commit/Git Log require an attached repository. Letters
stay fixed when entries are missing or disabled and across UI languages.

Both buttons retain the same display-layout icon in every view. Their default
tooltips are **Sidebar view (Ctrl+Shift+F9)** and **Content view
(Ctrl+Shift+F10)**. The toggle shows **Show sidebar (F9)** or **Hide sidebar (F9)**.

Ctrl+1–6 and Ctrl+Shift+1–4 no longer select views. Git actions use their existing
controls and menus without Git-local action shortcuts. Ctrl+Shift+P remains the
application Command Palette, including while a Git control has focus. Standard
Linux Shift+F10 and Menu-key context menus remain available; Ctrl+Shift+F10
opens Content view independently.
