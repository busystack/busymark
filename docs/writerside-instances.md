# Writerside instances

BusyMark treats every registered Writerside instance as a separate output with
its own tree, identity, status, publication path, version, and build settings.
The implementation follows JetBrains' published Writerside formats; it does not
introduce a BusyMark-specific project file.

## Instance actions

Open **Table of Contents**, select the instance icon, and use **TOC actions**
to:

- create an empty help instance;
- create an instance from selected local Markdown files;
- create a non-publishing TOC library;
- edit the selected instance;
- assign a local icon color; or
- open the authoritative `.tree` file.

The instance editor writes the documented locations:

- `id`, `name`, and `status` in `<instance-profile>`;
- `src`, `version`, and `web-path` in `writerside.cfg` (or `project.ihp`);
- `noindex-content` and `offline-docs` in the configured
  `buildprofiles.xml`.

An empty regular instance is valid. Its first newly created topic becomes its
`start-page`. A TOC library is written with `is-library="true"` and does not
have output settings of its own.

Changing an instance ID renames its `.tree` file and updates documented project
references, including instance filters, cross-instance `in` references,
instance groups, tree includes, topic title overrides, and build profiles.
BusyMark confirms this refactoring and explicitly warns that publication
scripts are not changed, matching JetBrains' documented behavior.

## Tree representation

The TOC model recognizes the documented `<toc-element>`, `<include>`, and
`<snippet>` hierarchy, including:

- local reusable tree sections;
- `instance` conditions, negation, and registered `@group` conditions;
- `filter` and `use-filter`, including the special `empty` filter;
- cross-instance `ref` and `in` topic references;
- `hidden`, `wip`, `href`, `toc-title`, `origin`, and redirect metadata; and
- library instances whose snippets are visible as reusable sections.

Resolved reusable entries are derived navigation state. Their source remains
the library `.tree` file, so BusyMark does not offer structural move/remove
actions that would mistakenly edit the consuming instance. Invalid, missing,
circular, unsafe, and cross-module includes remain visible and produce a
source-linked diagnostic. Cross-module `origin` references are preserved and
identified, but are not expanded when only one help module is open.

The selected instance and icon colors are local BusyMark preferences. They do
not modify or add undocumented Writerside project metadata.

## Example

[`demo/writerside-instances`](../demo/writerside-instances) is an openable
Writerside module with two output instances, a TOC library, instance groups,
custom filters, a cross-instance topic reference, per-instance build settings,
release/EAP statuses, hidden and work-in-progress topics, an external TOC
link, and redirect metadata.

## Authoritative references

- [Instances](https://www.jetbrains.com/help/writerside/instances.html)
- [writerside.cfg](https://www.jetbrains.com/help/writerside/writerside-cfg.html)
- [Conditional content](https://www.jetbrains.com/help/writerside/conditional-content.html)
- [Reuse topics and sections](https://www.jetbrains.com/help/writerside/reuse-topics.html)
- [Allow search engine indexing](https://www.jetbrains.com/help/writerside/allow-search-engine-indexing.html)
- [Offline documentation](https://www.jetbrains.com/help/writerside/offline-documentation.html)
- [Modules](https://www.jetbrains.com/help/writerside/help-modules.html)
