import 'package:flutter/widgets.dart';
import 'package:yaru/yaru.dart';

abstract final class BusyMarkGlyphs {
  const BusyMarkGlyphs._();

  static const IconData about = YaruIcons.information;
  static const IconData appearance = YaruIcons.desktop_appearance;
  static const IconData blockquote = YaruIcons.chat_text;
  static const IconData bold = YaruIcons.bold;
  static const IconData branch = YaruIcons.network_wired;
  static const IconData category = YaruIcons.tag;
  static const IconData check = YaruIcons.checkmark;
  static const IconData checkedBox = YaruIcons.checkbox_checked;
  static const IconData checklist = YaruIcons.task_list;
  static const IconData clear = YaruIcons.edit_clear;
  static const IconData clearAll = YaruIcons.edit_clear_all;
  static const IconData code = YaruIcons.code;
  static const IconData downArrow = YaruIcons.pan_down;
  static const IconData copy = YaruIcons.copy;
  static const IconData cut = YaruIcons.cut;
  static const IconData delete = YaruIcons.trash;
  static const IconData diagnostics = YaruIcons.task_list;
  static const IconData document = YaruIcons.document;
  static const IconData documentHistory = YaruIcons.document_history;
  static const IconData documentOpen = YaruIcons.document_open;
  static const IconData edit = YaruIcons.pen;
  static const IconData editorView = YaruIcons.text_editor;
  static const IconData error = YaruIcons.error;
  static const IconData externalLink = YaruIcons.external_link;
  static const IconData feedback = YaruIcons.chat_text;
  static const IconData folder = YaruIcons.folder;
  static const IconData folderOpen = YaruIcons.folder_open;
  static const IconData font = YaruIcons.font;
  static const IconData goTop = YaruIcons.go_top;
  static const IconData hardBreak = YaruIcons.go_down;
  static const IconData heading = YaruIcons.font;
  static const IconData hide = YaruIcons.hide;
  static const IconData history = YaruIcons.history;
  static const IconData home = YaruIcons.home;
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
  static const IconData pull = YaruIcons.download;
  static const IconData push = YaruIcons.send;
  static const IconData redo = YaruIcons.redo;
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
  static const IconData warning = YaruIcons.warning;
  static const IconData writersideProject = YaruIcons.book;

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
