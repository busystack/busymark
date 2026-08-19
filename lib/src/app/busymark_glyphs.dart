import 'package:flutter/material.dart' show Icons;
import 'package:flutter/widgets.dart';
import 'package:yaru/yaru.dart';

abstract final class BusyMarkGlyphs {
  const BusyMarkGlyphs._();

  static const IconData about = YaruIcons.information;
  static const IconData add = YaruIcons.plus;
  static const IconData ai = YaruIcons.star_filled;
  static const IconData appearance = YaruIcons.desktop_appearance;
  static const IconData blockquote = YaruIcons.chat_text;
  static const IconData bold = YaruIcons.bold;
  static const IconData branch = Icons.fork_right;
  static const IconData category = YaruIcons.tag;
  static const IconData check = YaruIcons.checkmark;
  static const IconData checkedBox = YaruIcons.checkbox_checked;
  static const IconData checklist = YaruIcons.task_list;
  static const IconData clear = YaruIcons.edit_clear;
  static const IconData clearAll = YaruIcons.edit_clear_all;
  static const IconData code = YaruIcons.code;
  static const IconData codeBlock = YaruIcons.terminal;
  static const IconData downArrow = YaruIcons.pan_down;
  static const IconData copy = YaruIcons.copy;
  static const IconData cut = YaruIcons.cut;
  static const IconData delete = YaruIcons.trash;
  static const IconData desktop = YaruIcons.desktop;
  static const IconData diagnostics = YaruIcons.task_list;
  static const IconData document = YaruIcons.document;
  static const IconData documentHistory = YaruIcons.document_history;
  static const IconData documentOpen = YaruIcons.document_open;
  static const IconData edit = YaruIcons.pen;
  static const IconData editorView = YaruIcons.text_editor;
  static const IconData error = YaruIcons.error;
  static const IconData exportPdf = YaruIcons.save_as;
  static const IconData externalLink = YaruIcons.external_link;
  static const IconData feedback = YaruIcons.chat_text;
  static const IconData fitWidth = YaruIcons.zoom_fit_best;
  static const IconData folder = YaruIcons.folder;
  static const IconData folderOpen = YaruIcons.folder_open;
  static const IconData font = YaruIcons.font;
  static const IconData fullScreen = YaruIcons.fullscreen;
  static const IconData goTop = YaruIcons.go_top;
  static const IconData hardBreak = YaruIcons.go_down;
  static const IconData heading = YaruIcons.font;
  static const IconData hide = YaruIcons.hide;
  static const IconData history = YaruIcons.history;
  static const IconData home = YaruIcons.home;
  static const IconData htmlBlock = YaruIcons.code;
  static const IconData image = YaruIcons.image;
  static const IconData imageMissing = YaruIcons.image_missing;
  static const IconData indent = YaruIcons.indent_more;
  static const IconData info = YaruIcons.information;
  static const IconData inlineImage = YaruIcons.insert_image;
  static const IconData insertObject = YaruIcons.insert_object;
  static const IconData italic = YaruIcons.italic;
  static const IconData keyboard = YaruIcons.keyboard_shortcuts;
  static const IconData link = YaruIcons.insert_link;
  static const IconData markdownFile = YaruIcons.text_editor;
  static const IconData menuHorizontal = YaruIcons.view_more_horizontal;
  static const IconData menuVertical = YaruIcons.view_more;
  static const IconData newDocument = YaruIcons.document_new;
  static const IconData orderedList = YaruIcons.ordered_list;
  static const IconData outdent = YaruIcons.indent_less;
  static const IconData paragraph = YaruIcons.insert_text;
  static const IconData paste = YaruIcons.paste;
  static const IconData preview = YaruIcons.eye;
  static const IconData previewView = YaruIcons.eye;
  static const IconData privacy = YaruIcons.shield_warning;
  static const IconData pull = YaruIcons.download;
  static const IconData push = YaruIcons.send;
  static const IconData redo = YaruIcons.redo;
  static const IconData refresh = YaruIcons.refresh;
  static const IconData save = YaruIcons.save;
  static const IconData search = YaruIcons.search;
  static const IconData searchUnavailable = YaruIcons.find_replace;
  static const IconData selectAll = YaruIcons.selection;
  static const IconData settings = YaruIcons.settings;
  static const IconData sidebar = YaruIcons.sidebar;
  static const IconData startTopic = YaruIcons.document;
  static const IconData strikethrough = YaruIcons.strikethrough;
  static const IconData sourceView = YaruIcons.code;
  static const IconData splitView = YaruIcons.panel_look;
  static const IconData symbols = YaruIcons.symbols;
  static const IconData tab = YaruIcons.tab_new;
  static const IconData table = YaruIcons.office_spreadsheet;
  static const IconData tag = YaruIcons.tag;
  static const IconData task = YaruIcons.checkbox;
  static const IconData text = YaruIcons.text_editor;
  static const IconData thematicBreak = YaruIcons.minus;
  static const IconData tip = YaruIcons.light_bulb_on;
  static const IconData toolbarPlacement = YaruIcons.go_top;
  static const IconData tree = YaruIcons.tree;
  static const IconData underline = YaruIcons.underline;
  static const IconData undo = YaruIcons.undo;
  static const IconData unorderedList = YaruIcons.unordered_list;
  static const IconData upArrow = YaruIcons.pan_up;
  static const IconData warning = YaruIcons.warning;
  static const IconData windowClose = YaruIcons.window_close;
  static const IconData writersideProject = YaruIcons.book;

  /// Maps Flutter menu glyphs to freedesktop themed-icon names for GTK.
  ///
  /// The native menu bridge cannot render an [IconData] font glyph directly.
  /// Keeping the mapping beside the semantic glyph catalog lets Flutter and
  /// GTK use equivalent, platform-native artwork for the same command.
  static String? nativeMenuIconName(IconData? icon) {
    if (icon == null) {
      return null;
    }
    if (icon == about || icon == info) {
      return 'help-about-symbolic';
    }
    if (icon == add) {
      return 'list-add-symbolic';
    }
    if (icon == appearance || icon == settings) {
      return 'preferences-system-symbolic';
    }
    if (icon == blockquote || icon == feedback) {
      return 'chat-symbolic';
    }
    if (icon == bold) {
      return 'format-text-bold-symbolic';
    }
    if (icon == branch || icon == tree) {
      return 'view-treemap-symbolic';
    }
    if (icon == category || icon == tag) {
      return 'tag-symbolic';
    }
    if (icon == checkedBox) {
      return 'checkbox-checked-symbolic';
    }
    if (icon == checklist || icon == diagnostics) {
      return 'view-tasks-unscheduled-symbolic';
    }
    if (icon == clear) {
      return 'edit-clear-symbolic';
    }
    if (icon == clearAll) {
      return 'edit-clear-all-symbolic';
    }
    if (icon == codeBlock) {
      return 'utilities-terminal-symbolic';
    }
    if (icon == code ||
        icon == htmlBlock ||
        icon == sourceView ||
        icon == symbols) {
      return 'text-x-generic-symbolic';
    }
    if (icon == copy) {
      return 'edit-copy-symbolic';
    }
    if (icon == cut) {
      return 'edit-cut-symbolic';
    }
    if (icon == delete) {
      return 'user-trash-symbolic';
    }
    if (icon == desktop) {
      return 'video-display-symbolic';
    }
    if (icon == document || icon == startTopic) {
      return 'text-x-generic-symbolic';
    }
    if (icon == documentHistory || icon == history) {
      return 'document-open-recent-symbolic';
    }
    if (icon == documentOpen) {
      return 'document-open-symbolic';
    }
    if (icon == edit) {
      return 'document-edit-symbolic';
    }
    if (icon == error) {
      return 'dialog-error-symbolic';
    }
    if (icon == externalLink) {
      return 'external-link-symbolic';
    }
    if (icon == folder) {
      return 'folder-symbolic';
    }
    if (icon == folderOpen) {
      return 'folder-open-symbolic';
    }
    if (icon == font || icon == heading) {
      return 'font-select-symbolic';
    }
    if (icon == fullScreen) {
      return 'view-fullscreen-symbolic';
    }
    if (icon == goTop || icon == toolbarPlacement) {
      return 'go-top-symbolic';
    }
    if (icon == downArrow || icon == hardBreak) {
      return 'go-down-symbolic';
    }
    if (icon == hide) {
      return 'eye-not-looking-symbolic';
    }
    if (icon == home) {
      return 'go-home-symbolic';
    }
    if (icon == image) {
      return 'image-x-generic-symbolic';
    }
    if (icon == imageMissing) {
      return 'image-missing-symbolic';
    }
    if (icon == indent) {
      return 'format-indent-more-symbolic';
    }
    if (icon == inlineImage) {
      return 'insert-image-symbolic';
    }
    if (icon == insertObject) {
      return 'insert-object-symbolic';
    }
    if (icon == italic) {
      return 'format-text-italic-symbolic';
    }
    if (icon == keyboard) {
      return 'input-keyboard-symbolic';
    }
    if (icon == link) {
      return 'insert-link-symbolic';
    }
    if (icon == markdownFile || icon == editorView || icon == text) {
      return 'accessories-text-editor-symbolic';
    }
    if (icon == newDocument) {
      return 'document-new-symbolic';
    }
    if (icon == orderedList) {
      return 'format-ordered-list-symbolic';
    }
    if (icon == outdent) {
      return 'format-indent-less-symbolic';
    }
    if (icon == paragraph) {
      return 'insert-text-symbolic';
    }
    if (icon == paste) {
      return 'edit-paste-symbolic';
    }
    if (icon == preview || icon == previewView) {
      return 'image-viewer-symbolic';
    }
    if (icon == privacy) {
      return 'security-high-symbolic';
    }
    if (icon == pull) {
      return 'folder-download-symbolic';
    }
    if (icon == push) {
      return 'document-send-symbolic';
    }
    if (icon == redo) {
      return 'edit-redo-symbolic';
    }
    if (icon == refresh) {
      return 'view-refresh-symbolic';
    }
    if (icon == exportPdf) {
      return 'document-save-as-symbolic';
    }
    if (icon == save) {
      return 'document-save-symbolic';
    }
    if (icon == search) {
      return 'system-search-symbolic';
    }
    if (icon == searchUnavailable) {
      return 'edit-find-replace-symbolic';
    }
    if (icon == selectAll) {
      return 'edit-select-all-symbolic';
    }
    if (icon == sidebar) {
      return 'sidebar-show-symbolic';
    }
    if (icon == strikethrough) {
      return 'format-text-strikethrough-symbolic';
    }
    if (icon == splitView) {
      return 'panel-right-symbolic';
    }
    if (icon == table) {
      return 'x-office-spreadsheet-symbolic';
    }
    if (icon == task) {
      return 'checkbox-symbolic';
    }
    if (icon == thematicBreak) {
      return 'list-remove-symbolic';
    }
    if (icon == underline) {
      return 'format-text-underline-symbolic';
    }
    if (icon == undo) {
      return 'edit-undo-symbolic';
    }
    if (icon == unorderedList) {
      return 'format-unordered-list-symbolic';
    }
    if (icon == upArrow) {
      return 'go-up-symbolic';
    }
    if (icon == warning) {
      return 'dialog-warning-symbolic';
    }
    if (icon == writersideProject) {
      return 'folder-documents-symbolic';
    }
    return null;
  }

  /// Resolves a navigation glyph against the surrounding reading direction.
  ///
  /// Yaru's directional glyphs do not opt in to Flutter's automatic icon
  /// mirroring, so callers must select the matching physical glyph instead.
  static IconData backFor(TextDirection direction) {
    return direction == TextDirection.rtl
        ? YaruIcons.arrow_right
        : YaruIcons.arrow_left;
  }

  static IconData forwardFor(TextDirection direction) {
    return direction == TextDirection.rtl
        ? YaruIcons.go_previous
        : YaruIcons.go_next;
  }

  static IconData collapsedTreeArrowFor(TextDirection direction) {
    return direction == TextDirection.rtl
        ? YaruIcons.pan_start
        : YaruIcons.pan_end;
  }

  static IconData indentFor(TextDirection direction) {
    return direction == TextDirection.rtl
        ? YaruIcons.indent_less
        : YaruIcons.indent_more;
  }

  static IconData outdentFor(TextDirection direction) {
    return direction == TextDirection.rtl
        ? YaruIcons.indent_more
        : YaruIcons.indent_less;
  }

  static IconData undoFor(TextDirection direction) {
    return direction == TextDirection.rtl ? YaruIcons.redo : YaruIcons.undo;
  }

  static IconData redoFor(TextDirection direction) {
    return direction == TextDirection.rtl ? YaruIcons.undo : YaruIcons.redo;
  }

  static IconData wordWrapFor(TextDirection direction) {
    return direction == TextDirection.rtl
        ? YaruIcons.text_direction_rtl
        : YaruIcons.text_direction_ltr;
  }
}
