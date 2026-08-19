# BusyMark local AI editing demo

This document contains realistic editing samples for every supported AI action.
Configure a local model under **Settings → AI**, then use the AI button in
Source or Editor view. Review every generated diff before applying it.

## Rewrite for clarity

Select the following paragraph and choose **Rewrite**:

The release process is something that has a number of steps which need to be
performed by the documentation owner, and those steps should be carried out in
the order in which they are described because doing them in another order can
cause the published documentation to become inconsistent with the application.

## Shorten without losing facts

Select the following paragraph and choose **Shorten**:

Before publishing the operator guide, the release engineer must validate all
internal links, build the English and German editions, retain the generated
reports for ninety days, and obtain approval from both the documentation lead
and the security reviewer. Publication must not begin until both approvals are
recorded in the release ticket.

## Proofread

Select the following paragraph and choose **Proofread**:

Each administrator configure the service before users signs in. The settings
is stored locally, and they must be reviewed when the server are upgraded.

## Change tone

Select the following paragraph, choose **Change tone**, and enter
`neutral technical documentation`:

Just flip this switch and you are good to go. If the network is acting weird,
give the service a minute and smash Retry again.

## Translate

Select the following paragraph, choose **Translate**, and enter a target
language such as `German`:

The maintenance window begins at 22:00 UTC. Save active work before the window
starts because the documentation service will be unavailable for approximately
fifteen minutes.

## Summarize a section

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

## Draft from notes

Select these notes, choose **Draft**, and enter
`Write a concise deployment prerequisites section`:

- Ubuntu 24.04 hosts
- outbound HTTPS to package mirror
- 8 GB RAM minimum, 16 GB recommended
- service account cannot log in interactively
- verify 20 GB free disk space before upgrade

## Protected Markdown regression check

Select this complete paragraph and choose **Rewrite**. BusyMark must reject the
proposal if the model changes the URL or inline code:

Run `busymark validate --strict` before following the
[production checklist](https://docs.example.test/releases/checklist).

Select the paragraph and fenced block together and choose **Rewrite**. BusyMark
must reject a proposal that changes the command inside the fence:

The health check returns JSON and must complete successfully before traffic is
enabled.

```bash
curl --fail --silent http://127.0.0.1:8080/health
```

## Stale proposal check

Start any action on a selection, then edit the document before generation
finishes. The proposal dialog must show that the result is stale and keep
**Apply proposal** disabled.
