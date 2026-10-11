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
