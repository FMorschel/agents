---
name: layered-architecture
description: "Use when designing, placing, implementing, or reviewing Dart/Flutter code against the default layered architecture (View → Controller → Service → Repository → Data Source, or Endpoint → Service → … for headless apps): layer responsibilities, dependency direction, Model vs. ViewModel, caching, and upward event flow via per-layer Streams. This is the fallback when the project has no architecture doc of its own — a project's own `architecture.md` always wins."
---

## Default layered architecture

Dependencies flow **downward only**: a layer calls the layer directly below it, never upward or sideways, and never skips a layer.

### Precedence

This is the *default*, not the law. Follow `resolve-project-conventions` first: if the project has its own `architecture.md` (or equivalent), use its layer names and rules and treat this skill only as background. Where the two disagree, the project doc wins and this skill's rule is not a finding. Say which source you used:

```
Architecture source: <project architecture.md | this skill's default | inferred from directories>
```

### Layers (UI app)

```
View (Widget)              observes a ViewModel, no logic
Controller                 knows Service; exposes ViewModel state to the View
Service / Use Case         knows Repository (interface); returns ViewModels
Repository (interface)     returns Models (domain)
Repository (implementation)knows Data Source / DB / ORM
Data Source / Gateway      raw I/O: HTTP, SQL, files, sockets (optional layer)
```

| Layer | Does | Must not |
|---|---|---|
| **View** | Render the current ViewModel; forward user input to the Controller | Business or orchestration logic |
| **Controller** | Receive input; format-level validation only ("is this parseable / non-empty?"); call a Service; update the ViewModel state | Business rules, storage, knowing how data is persisted |
| **Service** | Business rules and invariants; orchestrate one or more Repositories; transactions/rollback; map **Model → ViewModel** | Know about HTTP, widgets, SQL, or any infrastructure detail; return status codes |
| **Repository** | CRUD on one aggregate/entity; map Model ↔ storage format; encapsulate queries; primary home of domain caching | Business rules; calling another Repository; knowing ViewModels or widgets |
| **Data Source** | Raw I/O, (de)serialization, retries, connection handling, raw-response caching (ETag/304) | Domain rules; returning ViewModels |

### Headless variant (daemon, server, CLI, background service)

No View or ViewModel exists, so `View → ViewModel → Controller` collapses into one **Endpoint** (socket handler, RPC method, HTTP route, CLI command). It parses/validates the request format, calls a Service, and serializes the result. Service and below are identical to the UI variant; they cannot tell which kind of entry point sits above them.

### Key rules

1. **Depend on abstractions.** A Service takes `OrderRepository` (abstract), never `SqliteOrderRepository`. Swapping storage must be a DI binding change only.
2. **Models are pure.** Plain Dart classes: no framework imports, no annotations, no JSON keys. Mapping to/from storage happens at the Repository boundary.
3. **ViewModels are UI-shaped and separate from Models.** They hold what the View displays (formatted strings, labels). The Service maps Model → ViewModel; a Repository never sees one.
4. **One direction only.** A Repository importing a Widget or ViewModel, or a Service returning an HTTP status, has crossed a boundary.
5. **Services orchestrate, Repositories operate.** An operation touching two Repositories is coordinated by the Service. A Repository never calls another Repository.
6. **Add layers only when the pain justifies it.** Small features may be Controller → Service → Repository. Add a Data Source when there are multiple sources (local + remote + cache). A dedicated Domain layer (entities, value objects) is the step toward full Clean Architecture, not the default.

### Caching

- Cache **Models at the Repository** using the **decorator pattern**: `CachedXRepository implements XRepository` wraps the real one, so adopting it is a DI change and the Service is untouched. Update the cache on writes.
- Cache **raw responses at the Data Source** (ETag/304, response bodies) — an I/O concern, not a domain one.
- Cache **ViewModels at the Service** only for a measured performance reason (expensive multi-repository aggregation). Uncommon; treat an unexplained ViewModel cache as a smell.

### Upward events without upward dependencies

Background pushes (acks, state changes, takeovers) originate at the bottom and must reach the top. This does not break "downward only", because *dependency direction* (compile-time imports) and *data flow* (runtime) are separate:

- Each layer exposes its own `Stream` and emits into it without knowing its listeners.
- A layer subscribes **only to the stream of the layer directly below it**, re-shaping and re-emitting for the layer above when the event must travel further (Data Source → Repository → Service → Controller/Endpoint).
- **No shared or global event bus**, and no lower layer importing an upper layer's type to notify it.
- Stream lifecycle (cancel subscriptions, close controllers) belongs to `review-flutter-async-and-disposal`.

### When reviewing

Flag, in this order of severity:

1. **Upward or sideways dependency** — a lower layer importing an upper layer's type; a Repository calling a Repository.
2. **Skipped layer** — Controller/Endpoint calling a Repository or Data Source directly.
3. **Concrete injection** — a Service or Controller constructed against an implementation instead of the abstract Repository.
4. **Leaky types** — framework, JSON, or DB types in a Model; a ViewModel below the Service; an HTTP or SQL concept above the Data Source/Repository.
5. **Misplaced logic** — business rules in a Controller/Repository; storage or query logic in a Service; orchestration in a View.
6. **Misplaced caching** — see Caching above.
7. **Global event bus** or a lower layer pushing directly to an upper one.

Only call something a violation when it clearly breaks a rule above (or the project doc). If it is merely unusual, ask — "does this project forbid X?" — per `resolve-project-conventions`.

### When placing new code

Ask, top-down: *Is it about pixels or input?* → View/Controller. *A business rule or a workflow across entities?* → Service. *How one entity is loaded/saved?* → Repository. *The wire or the disk itself?* → Data Source. If a new method does not clearly belong to exactly one layer, it is doing two jobs — split it.

The full spec, with worked examples (ViewModel, Controller, Service, Repository, Data Source, caching decorator, per-layer streams), is in [references/layered-architecture.md](references/layered-architecture.md). Load it only when you need the fuller rationale or a concrete shape to imitate.
