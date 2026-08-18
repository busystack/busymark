# PlantUML browser-build conformance corpus

These diagrams cover the PlantUML families supported for BusyMark's first release.

## Sequence

```plantuml
@startuml
Alice -> Bob: Hello
Bob --> Alice: Ready
@enduml
```

## Class

```puml
@startuml
class Document {
  +title: String
  +render(): Svg
}
interface Renderer
Renderer <|.. Document
@enduml
```

## Component

```plantuml
@startuml
component BusyMark
component Renderer
BusyMark --> Renderer
@enduml
```

## Deployment

```plantuml
@startuml
node "Linux desktop" {
  artifact BusyMark
  node WebKitGTK
}
BusyMark --> WebKitGTK
@enduml
```

## State

```plantuml
@startuml
[*] --> Editing
Editing --> Rendering
Rendering --> Ready
Rendering --> Editing : invalid source
Ready --> [*]
@enduml
```

## Activity

```plantuml
@startuml
start
:Parse source;
if (Valid?) then (yes)
  :Render SVG;
else (no)
  :Keep last valid render;
endif
stop
@enduml
```

## Use case

```plantuml
@startuml
left to right direction
actor Author
rectangle BusyMark {
  usecase "Preview diagram" as Preview
  usecase "Export PDF" as Export
}
Author --> Preview
Author --> Export
@enduml
```

## Entity relationship

```plantuml
@startuml
entity Document {
  * id : UUID
  --
  title : text
}
entity Diagram {
  * id : UUID
  document_id : UUID
}
Document ||--o{ Diagram
@enduml
```

## Mind map

```plantuml
@startmindmap
* BusyMark
** Preview
*** Mermaid
*** PlantUML
*** D2
** API Reference
*** OpenAPI
@endmindmap
```

## Work breakdown structure

```plantuml
@startwbs
* Release
** Renderers
*** Mermaid
*** PlantUML
*** D2
** OpenAPI
** PDF tests
@endwbs
```

## Gantt

```plantuml
@startgantt
Project starts 2026-08-18
[Renderer contracts] lasts 2 days
[Preview integration] starts at [Renderer contracts]'s end and lasts 2 days
[PDF verification] starts at [Preview integration]'s end and lasts 1 day
@endgantt
```

## JSON

```plantuml
@startjson
{
  "offline": true,
  "engines": ["Mermaid", "PlantUML", "D2", "OpenAPI"]
}
@endjson
```

## YAML

```plantuml
@startyaml
application: BusyMark
offline: true
renderers:
  - Mermaid
  - PlantUML
  - D2
@endyaml
```
