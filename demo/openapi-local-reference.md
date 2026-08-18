# OpenAPI local-reference demo

The parser resolves this relative file inside the canonical workspace root.

```oas
openapi: 3.1.0
info:
  title: Local Reference Demo
  version: 1.0.0
paths:
  /nodes/{id}:
    get:
      operationId: getNode
      parameters:
        - name: id
          in: path
          required: true
          schema:
            type: string
      responses:
        "200":
          description: A recursive node
          content:
            application/json:
              schema:
                $ref: "./openapi/components.yaml#/components/schemas/Node"
```
