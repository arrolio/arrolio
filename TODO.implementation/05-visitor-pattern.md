---
priority: P1
phase: 1
depends_on: [02, 03]
layer: foundation
est: 1d
status: pending
---

## Problem

Engine and Renderer both walk trees of typed nodes. Without a
visitor pattern, every walker re-implements dispatch. A canonical
visitor keeps the dispatch logic in one place and lets new walkers
(validator, optimizer, debug-dumper) be added without touching node
classes (OCP).

## Approach

Files under `lib/arrolio/visitor/`:

- `base.rb` — `Visitor::Base` with `visit(node)` that dispatches on
  `node.class` to a method named `visit_<class_name>`. Falls back to
  `visit_unknown(node)` if no specific method.
- `content_visitor.rb` — mixin giving `visit_section`, `visit_paragraph`,
  etc. defaults that recurse into children.
- `layout_spec_visitor.rb` — same idea for LayoutSpec nodes.

Built-in visitors:
- `Validator` — raises `ContentError` / `LayoutSpecError` on bad trees.
- `Dumper` — prints tree as YAML for debugging.
- `Counter` — counts nodes per role (used by harness TODO 53).

## Done-When

- [ ] `Visitor::Base.dispatch(node)` routes to `visit_<class>`.
- [ ] Unknown classes hit `visit_unknown` (default: no-op).
- [ ] `ContentVisitor` walks a `Content::Document` end-to-end.
- [ ] `Validator` flags a Section with non-String title.
- [ ] Specs cover dispatch, recursion, unknown class.
