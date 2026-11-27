import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:path/path.dart' as p;
import 'package:url_launcher/url_launcher.dart';

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
    return AlertDialog(
      title: Text(l10n.insertAudio),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              OutlinedButton.icon(
                onPressed: () =>
                    Navigator.pop(context, const AudioInsertion.file()),
                icon: const Icon(BusyMarkGlyphs.audioFile),
                label: Text(l10n.audioCopyFile),
              ),
              if (widget.canLinkFile)
                OutlinedButton.icon(
                  onPressed: () => Navigator.pop(
                    context,
                    const AudioInsertion.file(link: true),
                  ),
                  icon: const Icon(BusyMarkGlyphs.link),
                  label: Text(l10n.audioLinkFile),
                ),
              const SizedBox(height: 14),
              TextField(
                controller: _url,
                decoration: InputDecoration(
                  labelText: l10n.audioUrl,
                  errorText: _error,
                ),
                onChanged: (_) => setState(() => _error = null),
                onSubmitted: (_) => _insertUrl(),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton(onPressed: _insertUrl, child: Text(l10n.insertAudio)),
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
    return AlertDialog(
      title: Text(l10n.audioProperties),
      content: SizedBox(
        width: 570,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _markup,
                minLines: 3,
                maxLines: 10,
                decoration: InputDecoration(
                  labelText: l10n.audioMarkup,
                  errorText: _error,
                ),
                onChanged: (_) => setState(() => _error = null),
              ),
              if (widget.localPath != null)
                Wrap(
                  children: [
                    TextButton(
                      onPressed: () => unawaited(_open(false)),
                      child: Text(l10n.audioExternalOpen),
                    ),
                    TextButton(
                      onPressed: () => unawaited(_open(true)),
                      child: Text(l10n.audioShowFolder),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, ''),
          child: Text(l10n.audioRemove),
        ),
        FilledButton(onPressed: _apply, child: Text(l10n.apply)),
      ],
    );
  }
}
