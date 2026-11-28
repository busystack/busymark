import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:path/path.dart' as p;
import 'package:url_launcher/url_launcher.dart';

import '../app/busymark_design.dart';
import '../app/busymark_glyphs.dart';
import '../app/localization.dart';
import '../markdown/audio_media.dart';
import '../markdown/audio_syntax.dart';

class AudioInsertion {
  const AudioInsertion.file({this.link = false}) : url = null;
  const AudioInsertion.remote(this.url) : link = false;

  final String? url;
  final bool link;
}

class InsertAudioDialog extends StatefulWidget {
  const InsertAudioDialog({super.key, required this.canLinkFile});

  final bool canLinkFile;

  @override
  State<InsertAudioDialog> createState() => _InsertAudioDialogState();
}

class _InsertAudioDialogState extends State<InsertAudioDialog> {
  final _url = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _url.dispose();
    super.dispose();
  }

  void _insertUrl() {
    final url = Uri.tryParse(_url.text.trim());
    if (url == null ||
        url.scheme != 'https' ||
        !url.hasAuthority ||
        url.host.isEmpty ||
        url.userInfo.isNotEmpty) {
      setState(() => _error = context.l10n.audioInvalidUrl);
      return;
    }
    Navigator.pop(context, AudioInsertion.remote(url.toString()));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BusyMarkDialogShell(
      title: l10n.insertAudio,
      maxWidth: BusyMarkSizes.dialogNarrow,
      actions: [
        BusyMarkDialogButton(
          label: l10n.cancel,
          onPressed: () => Navigator.pop(context),
        ),
        BusyMarkDialogButton(
          label: l10n.insertAudio,
          onPressed: _insertUrl,
          suggested: true,
        ),
      ],
      children: [
        BusyMarkGroupedList(
          filled: true,
          children: [
            BusyMarkActionRow(
              title: l10n.audioCopyFile,
              titleWidget: Text(l10n.audioCopyFile),
              leading: const Icon(BusyMarkGlyphs.audioFile),
              onTap: () => Navigator.pop(context, const AudioInsertion.file()),
            ),
            if (widget.canLinkFile)
              BusyMarkActionRow(
                title: l10n.audioLinkFile,
                titleWidget: Text(l10n.audioLinkFile),
                leading: const Icon(BusyMarkGlyphs.link),
                onTap: () => Navigator.pop(
                  context,
                  const AudioInsertion.file(link: true),
                ),
              ),
          ],
        ),
        const SizedBox(height: BusyMarkSpacing.md),
        BusyMarkGroupedList(
          filled: true,
          children: [
            BusyMarkGroupedTextEntry(
              label: l10n.audioUrl,
              controller: _url,
              errorText: _error,
              keyboardType: TextInputType.url,
              autocorrect: false,
              enableSuggestions: false,
              onChanged: (_) => setState(() => _error = null),
              onSubmitted: (_) => _insertUrl(),
            ),
          ],
        ),
      ],
    );
  }
}

class AudioPropertiesDialog extends StatefulWidget {
  const AudioPropertiesDialog({super.key, required this.audio, this.localPath});

  final BusyAudio audio;
  final String? localPath;

  @override
  State<AudioPropertiesDialog> createState() => _AudioPropertiesDialogState();
}

class _AudioPropertiesDialogState extends State<AudioPropertiesDialog> {
  late final _markup = TextEditingController(text: widget.audio.rawSource);
  String? _error;

  @override
  void dispose() {
    _markup.dispose();
    super.dispose();
  }

  void _apply() {
    final markup = _markup.text.trim();
    if (authoredAudioOpening.matchAsPrefix(markup) == null ||
        authoredAudioEnd(markup, 0) != markup.length) {
      setState(() => _error = context.l10n.audioInvalidMarkup);
      return;
    }
    Navigator.pop(context, markup);
  }

  Future<void> _open(bool folder) async {
    final path = widget.localPath;
    if (path == null) return;
    try {
      if (await launchUrl(Uri.file(folder ? p.dirname(path) : path))) return;
    } on Exception {
      // The desktop file handler may be unavailable.
    }
    if (mounted) setState(() => _error = context.l10n.audioCannotResolve);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BusyMarkDialogShell(
      title: l10n.audioProperties,
      maxWidth: BusyMarkSizes.dialogWide,
      actions: [
        BusyMarkDialogButton(
          label: l10n.cancel,
          onPressed: () => Navigator.pop(context),
        ),
        BusyMarkDialogButton(
          label: l10n.audioRemove,
          onPressed: () => Navigator.pop(context, ''),
          destructive: true,
        ),
        BusyMarkDialogButton(
          label: l10n.apply,
          onPressed: _apply,
          suggested: true,
        ),
      ],
      children: [
        BusyMarkGroupedList(
          filled: true,
          children: [
            BusyMarkGroupedTextEntry(
              label: l10n.audioMarkup,
              controller: _markup,
              minLines: 3,
              maxLines: 10,
              errorText: _error,
              autocorrect: false,
              enableSuggestions: false,
              onChanged: (_) => setState(() => _error = null),
            ),
            if (widget.localPath != null) ...[
              BusyMarkActionRow(
                title: l10n.audioExternalOpen,
                onTap: () => unawaited(_open(false)),
              ),
              BusyMarkActionRow(
                title: l10n.audioShowFolder,
                onTap: () => unawaited(_open(true)),
              ),
            ],
          ],
        ),
      ],
    );
  }
}
