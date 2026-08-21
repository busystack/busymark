---
title: BusyMark AI editing release qualification
audience: documentation-engineering
---

# BusyMark AI editing release qualification

Use this non-sensitive document to qualify an exact provider and model before a
release. In **Settings → AI**, configure Local Ollama, OpenAI, or Google Gemini,
run **Test connection**, and record the provider/model shown in each proposal.
For a cloud provider, confirm the disclosure before sending this content. Work
in **Source** view and review every diff before applying it.

## Rewrite for clarity

Select the following paragraph and choose **Rewrite**:

The release process is something that has a number of steps which need to be
performed by the documentation owner, and those steps should be carried out in
the order in which they are described because doing them in another order can
cause the published documentation to become inconsistent with the application.

Expected quality: concise professional prose, unchanged meaning, and no added
facts.

## Shorten without losing requirements

Select the following paragraph and choose **Shorten**:

Before publishing the operator guide, the release engineer must validate all
internal links, build the English and German editions, retain the generated
reports for ninety days, and obtain approval from both the documentation lead
and the security reviewer. Publication must not begin until both approvals are
recorded in the release ticket.

Expected quality: every language, retention period, approval, and ordering
constraint remains present.

## Proofread

Select the following paragraph and choose **Proofread**:

Each administrator configure the service before users signs in. The settings
is stored locally, and they must be reviewed when the server are upgraded.

Expected quality: grammar and agreement are corrected without changing the
operational requirement.

## Change tone

Select the following paragraph, choose **Change tone**, and enter
`neutral technical documentation`:

Just flip this switch and you are good to go. If the network is acting weird,
give the service a minute and smash Retry again.

Expected quality: the instructions become professional without inventing a
different control, wait time, or recovery procedure.

## Translate

Select the following paragraph, choose **Translate**, and enter a target
language such as `German`:

The maintenance window begins at 22:00 UTC. Save active work before the window
starts because the documentation service will be unavailable for approximately
fifteen minutes.

Expected quality: `22:00 UTC` and the fifteen-minute duration remain exact.

## Summarize

Select the following three paragraphs and choose **Summarize**:

The migration begins with a read-only inventory of every published space. The
inventory records the owning team, current release, custom domain, and number
of active readers. It does not copy document content.

After the owners approve the inventory, the migration tool creates the target
spaces and copies one release at a time. Each copied release is validated
before its target space becomes visible.

The old service remains available for seven days after validation. During that
period it is read-only, and all new changes must be made in the target service.
The operations team removes the old service only after the rollback period.

Expected quality: inventory, approval, per-release validation, and the
seven-day rollback period all survive in a concise summary. Also run Summarize
with no selection to qualify whole-document context disclosure and insertion.

## Draft from notes

Place the cursor after these notes, choose **Draft**, and enter
`Write a concise deployment prerequisites section`:

- Ubuntu 24.04 hosts
- outbound HTTPS to the approved package mirror
- 8 GB RAM minimum; 16 GB recommended
- a non-interactive service account
- 20 GB free disk space before upgrade

Expected quality: valid Markdown using only the supplied requirements.

## Fenced-code assistance

Place the cursor inside this fence and choose **Explain code block**. The
proposal should insert a concise explanation after the fence without changing
the code.

```dart
Iterable<String> releaseTags(Iterable<String> tags) sync* {
  for (final tag in tags) {
    if (tag.startsWith('release/')) yield tag.substring(8);
  }
}
```

Next choose **Improve code block**. BusyMark must accept only a proposal that
replaces exactly this complete fence while preserving the `dart` language
identifier. Review behavior changes rather than assuming generated code is
correct.

## Protected Markdown regression fixture {#protected-fixture}

Select only the prose in the next paragraph and choose **Rewrite**. BusyMark may
change the prose but must reject a result that swaps or alters either link:

Read the [operator guide][operations] before opening the
[release checklist](https://docs.example.test/releases/checklist).

Select the rest of this section and choose **Rewrite**. BusyMark must reject a
proposal that changes the reference/footnote identifiers, URL associations,
autolink, table structure, heading ID, Writerside element, or code:

Use ``code ` value`` and retain incident evidence for seven days.[^retention]
Report status through <https://status.example.test>.

| Environment | Approval |
| --- | --- |
| Production | Security reviewer |

<note title="Do not remove">This is Writerside markup.</note>

```bash
curl --fail --silent http://127.0.0.1:8080/health
```

[operations]: https://docs.example.test/operations
[^retention]: The seven-day period begins after validation.

## Stale, cancellation, and request isolation

Start an action, edit the document before generation finishes, and verify that
**Apply proposal** remains disabled. Start a second action on the same target
and verify that the older request is cancelled. Cancel a streaming proposal and
verify that no partial text reaches the editor.

## Git commit-message draft

In a disposable Git repository, stage a small documentation edit while leaving
a different edit unstaged. In **Git → Changes**, choose **Draft with AI**.
Verify that:

- the disclosure identifies a staged Git diff;
- the proposal describes only staged changes;
- accepting it fills, but does not submit, the commit-message field;
- the subject is at most 72 characters;
- a body, when present, follows a blank line;
- no file is staged, unstaged, or committed by the AI action.

## Deterministic checks

Choose **Generate/update table of contents** twice. Verify that one
marker-delimited TOC is generated and the second run updates it rather than
duplicating it. Then introduce a skipped heading level, an empty link, and an
empty table header to verify that BusyMark reports deterministic accessibility
diagnostics without making an AI request.

## Qualification record

Record the release result outside this demo document:

| Field | Result |
| --- | --- |
| BusyMark version | |
| Provider | |
| Exact model | |
| Connection test | Pass / Fail |
| Editing actions | Pass / Fail |
| Markdown protection | Pass / Fail |
| Code assistance | Pass / Fail |
| Git draft | Pass / Fail |
| Cancellation/staleness | Pass / Fail |
| Reviewer and date | |
