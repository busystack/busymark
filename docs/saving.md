# Saving documents

Use **Save** or **Save As…** in the Main menu or search for either command in
**Actions**. The default shortcuts are **Ctrl+S** and **Ctrl+Shift+S**. The menu
shows the current bindings, including changes made in Keyboard Shortcuts
settings.

Both commands work with Auto Save on or off. **Save** requests persistence
immediately. Use it to save an untitled document, resolve a save decision, or
save an edit before Auto Save runs.

| Active document | Save | Save As… |
| --- | --- | --- |
| Standalone Markdown | Updates the current file or asks where to save an untitled document | Saves to the chosen file and binds the same tab to that path. The previous file remains. |
| Writerside Markdown | Updates the project document | Writes one separate Markdown file. The project tab and references keep their original paths. |
| Nextcloud note | Stores edits on the device and schedules synchronization under the Notes settings | Writes a local Markdown copy and available managed attachments. The tab stays bound to the original note. |

Writerside **Save As…** is available for Markdown source. Other supported
Writerside source files still use **Save**. A Writerside or Nextcloud copy
includes the captured editor content. The original's save status follows its
own Save and Auto Save operations. Nextcloud copies can be made offline when
the needed content and attachment bytes are available on the device.

The bottom bar shows the active document's save status next to its text format.
**Saved** means the file matches the known saved content and format.
**Modified** means edits remain. **Saving…** means the current revision is
being written. **Not saved** identifies an untitled document without an
established file. The bar also reports conflicts, missing files and save
failures. Local History and recovery can retain work independently of the file.

For Nextcloud, **Saved locally** describes durable content on the device.
The accompanying status says whether synchronization is pending, active, offline
or failed. **Synced** requires server acknowledgment of the note and its
pending work. Pending synchronization alone does not add a modified dot.
