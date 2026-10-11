---
switcher-label: Author's: &quot;Desktop&quot; \ Keys &amp; Tools
---

# Markdown Properties

Text **bold**.
{id="intro"}

## State only {id="md-state" default-state="expanded"}

Content.

```text
inline
```
{id="md-code" collapsible="false"}

```text
```
{id="md-file" src="sample.txt" include-lines="2-3" emphasize-lines="1"}

![Markdown Logo][logo]{id="image-markdown" width="48" thumbnail="true"}

[logo]: logo.png

Before [![Original][logo]{id="source-override" src="other.png" alt="Different" width="80" style="inline"}](properties.topic) after.

Read [one](properties.topic#image-xml){id="reference-override"} and [two][guide].

[guide]: properties.topic#image-paragraph

![Original][logo]{id="empty-alt" alt=""}

```java
hello
```
{id="lang-override" lang="text"}

<code-block id="embedded-code" lang="text" collapsible="false" default-state="expanded" switcher-key="platform">embedded code</code-block>

Use `{id="literal-code"}`.
{id="paragraph-code-owner"}

Use \{id="literal-escaped"\}.
{id="paragraph-escaped-owner"}

Read [**reference**](properties.topic){id="owned-link"}.
{id="paragraph-link-owner"}

Show ![Logo](logo.png){id="owned-image" width="24"}.
{id="paragraph-image-owner"}

- Native first item
- Native second item

{id="native-list" instance="conformance"}

<list type="bullet">
<li><p>First <b>item</b>.</p></li>
<li id="converted-list-item" instance="conformance" filter="release"><p>Second item.</p></li>
</list>

> A **note**.

{style="note" id="native-note" instance="conformance" filter="release"}

- [x] Checked native
- [ ] Unchecked native

{id="checked-native-list"}

<list type="checkbox" id="checked-xml-list">
<li id="checked-xml-item" checked="true"><p>Checked XML</p></li>
<li id="unchecked-xml-item" checked="false"><p>Unchecked XML</p></li>
</list>

See [`{id="linked-literal"}`](properties.topic){id="code-reference"}

Show ![\{id="image-literal"}](logo.png){id="alt-reference" width="24"}

Native authored start override.

3. Native parent
   4. Native nested first
   5. Native nested second
4. Native sibling

{start="10" id="native-numbered-list"}

Native marker starts.

3. Native marker parent
   4. Native marker nested first
   5. Native marker nested second
4. Native marker sibling

{id="native-marker-list"}

Native nested authored start override.

3. Native override parent
   4. Native override nested first
   5. Native override nested second

   {start="7" id="native-nested-list"}

4. Native override sibling

{start="10" id="native-override-list"}

Converted numbered lists.

<list start="10" id="numbered-list" type="decimal">

<li id="numbered-parent">

<p>Parent</p>

<list type="decimal" start="4">

<li>

<p>Nested first</p>

</li>

<li>

<p>Nested second</p>

</li>

</list>

</li>

<li>

<p>Sibling</p>

</li>

</list>

<list type="decimal" start="3">

<li id="marker-parent">

<p>Parent</p>

<list type="decimal" start="4">

<li>

<p>Nested first</p>

</li>

<li>

<p>Nested second</p>

</li>

</list>

</li>

<li>

<p>Sibling</p>

</li>

</list>

<list start="10" type="decimal">

<li id="nested-parent">

<p>Parent</p>

<list start="7" id="nested-list" type="decimal">

<li>

<p>Nested first</p>

</li>

<li>

<p>Nested second</p>

</li>

</list>

</li>

<li>

<p>Sibling</p>

</li>

</list>
