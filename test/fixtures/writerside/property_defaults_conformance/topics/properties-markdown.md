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
