import 'package:busymark/l10n/generated/app_localizations.dart';
import 'package:busymark/src/app/app_settings.dart';
import 'package:busymark/src/app/path_label.dart';
import 'package:busymark/src/workspace/recent_presentation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Recent locations follow resource owners and the actual home', (
    tester,
  ) async {
    late BuildContext context;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (c) {
            context = c;
            return const SizedBox();
          },
        ),
      ),
    );
    RecentResource resource(
      String path, {
      bool document = false,
      String? title,
      String? owner,
    }) => RecentResource(
      path: path,
      kind: document ? 'singleMarkdown' : 'markdownFolder',
      document: document,
      title: title,
      ownerRoot: owner,
      lastOpenedAt: DateTime(2026),
    );
    const home = '/actual-home';
    final workspace = resource('$home/Documents/dev-notes', title: 'dev-notes');
    final topic = resource(
      '$home/Documents/dev-notes/topics/security.md',
      document: true,
      title: 'Snap Security Updates',
    );
    String location(RecentResource r, {List<RecentResource>? owners}) =>
        recentResourceLocation(
          context,
          r,
          homeDirectory: home,
          recentResources: owners ?? [workspace],
        );
    expect(location(workspace), '~/Documents');
    expect(location(topic), 'dev-notes/topics');
    expect(
      location(
        resource('$home/Downloads/software_engineer_resume.md', document: true),
      ),
      '~/Downloads',
    );
    expect(
      location(
        resource(
          '$home/Downloads/books-client-gateway-agent.md',
          document: true,
          title: 'A custom title',
        ),
      ),
      '~/Downloads',
    );
    expect(
      recentResourceLocation(
        context,
        resource('$home/Downloads/resume.md', document: true),
        homeDirectory: home,
        workspaceRoot: '$home/Downloads',
      ),
      '~/Downloads',
    );
    expect(
      location(resource('/home/albert/Downloads/resume.md', document: true)),
      '/home/albert/Downloads',
    );
    expect(
      location(
        resource('/actual-home-other/Downloads/resume.md', document: true),
      ),
      '/actual-home-other/Downloads',
    );
    expect(
      location(
        resource(
          '/srv/projects/topic.topic',
          document: true,
          owner: '/srv/projects',
        ),
      ),
      '/srv/projects',
    );
    final duplicate = resource('$home/Archive/dev-notes');
    expect(
      location(topic, owners: [workspace, duplicate]),
      '~/Documents/dev-notes/topics',
    );
    final otherTopic = resource(
      '$home/Archive/dev-notes/topics/security.md',
      document: true,
      owner: '$home/Archive/dev-notes',
    );
    expect(
      location(
        resource(topic.path, document: true, owner: workspace.path),
        owners: [otherTopic],
      ),
      '~/Documents/dev-notes/topics',
    );
    final remote = RecentResource(
      path: '',
      kind: 'nextcloudNote',
      document: true,
      accountId: 'private-id',
      localId: 'stable-id',
      accountLabel: 'Alex · notes.example',
      lastOpenedAt: DateTime(2026),
    );
    expect(location(remote), 'Alex · notes.example');
    expect(topic.path, '$home/Documents/dev-notes/topics/security.md');
  });

  for (final direction in TextDirection.values) {
    testWidgets(
      'one measured path elision retains the useful end in $direction',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Directionality(
              textDirection: direction,
              child: MediaQuery(
                data: const MediaQueryData(textScaler: TextScaler.linear(1.6)),
                child: const Align(
                  alignment: Alignment.topLeft,
                  child: SizedBox(
                    width: 180,
                    child: BusyMarkPathLabel(
                      path:
                          '/a-very-long-parent-name/another-long-parent/topics',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        final text = tester.widget<Text>(
          find.descendant(
            of: find.byType(BusyMarkPathLabel),
            matching: find.byType(Text),
          ),
        );
        expect(text.data, startsWith('/…/'));
        expect(text.data, endsWith('/topics'));
        expect('…'.allMatches(text.data!).length, 1);
        expect(text.overflow, TextOverflow.clip);
        expect(text.maxLines, 1);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
