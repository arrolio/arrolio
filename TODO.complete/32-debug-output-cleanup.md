---
priority: P1
impact: med
depends_on: []
layer: render
status: done
est: 0.5d
---

## Problem

The codebase has ~30 `warn` calls used for debug tracing scattered
throughout production code:
- `Renderer::Pdf`: font embedding tracing, outline build tracing,
  image registration tracing, logo load tracing
- `Adapter`: (none after decomposition)
- `FlowBuilder`: image resolution tracing
- `Engine::Paged`: heading recording (implicit)

These pollute stdout/stderr during normal operation, make the
pipeline noisy, and have no way to be silenced in production.

## Approach

Introduce `Arroolio::Logger` as a structured logging facade:

```ruby
module Arroolio
  class Logger
    LEVELS = { debug: 0, info: 1, warn: 2, error: 3 }.freeze

    def self.level=(lvl); @level = LEVELS.fetch(lvl, 1); end
    def self.debug(msg); emit(:debug, msg); end
    def self.info(msg);  emit(:info, msg); end
    # ...

    def self.emit(lvl, msg)
      return if @level && LEVELS[lvl] < @level
      target.puts "[#{lvl}] #{msg}"
    end
  end
end
```

Replace all `warn` calls with `Logger.debug(...)` or `Logger.info(...)`.
Default level: `:warn` (silences debug/info). Set via
`ARROOLIO_LOG_LEVEL=debug` env var or `Arroolio::Logger.level = :debug`.

## Done-When

- [ ] No `warn` calls in production code (only in scripts/).
- [ ] `Arroolio::Logger` facade exists with level filtering.
- [ ] Default rendering produces zero stderr output.
- [ ] `ARROOLIO_LOG_LEVEL=debug` restores tracing for development.
- [ ] Specs cover: level filtering, message routing.

## Implementation

`lib/arrolio/logger.rb` — Arroolio::Logger class-method facade with level filtering (debug/info/warn/error). Default :warn silences debug/info. Env var ARROOLIO_LOG_LEVEL overrides. All 15 `warn` calls in lib/ replaced with Logger.debug/warn. Pipeline output now 1 line instead of 30+. 9 specs in spec/arrolio/logger_spec.rb.
