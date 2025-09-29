# NoSleep.jl

[![Autotest](https://github.com/hetalang/NoSleep.jl/actions/workflows/ci.yml/badge.svg)](https://github.com/hetalang/NoSleep.jl/actions/workflows/ci.yml)
<!--[![version](https://juliahub.com/docs/NoSleep/version.svg)](https://juliahub.com/ui/Packages/NoSleep/IIE0h)-->
[![GitHub issues](https://img.shields.io/github/issues/hetalang/NoSleep.jl.svg)](https://GitHub.com/hetalang/NoSleep.jl/issues/)
[![GitHub license](https://img.shields.io/github/license/hetalang/NoSleep.jl.svg)](https://github.com/hetalang/NoSleep.jl/blob/master/LICENSE)

Prevent your machine from going to sleep while long-running Julia jobs are executing — and automatically restore normal behavior when they finish or fail.

- **Cross-platform backend**  
  - Windows: `SetThreadExecutionState`
  - macOS: `caffeinate`
  - Linux: `systemd-inhibit`
- **Simple API**: block-style or manual on/off.
- **Safe by design**: resets on exit; optional timeout.

## Installation

```julia
] add NoSleep
```

## Usage

Macros style:

```julia
using NoSleep

@nosleep begin
    # long-running code here
end
```

Block style:

```julia
using NoSleep

with_nosleep() do
    # long-running code here
end
```

Manual style:

```julia
using NoSleep

nosleep_on()

# long-running code here

nosleep_off()
```

## Extra options

- Keep display awake: `keep_display=true` to prevent screen from going to sleep (default is `false`).
- Timeout: `timeout_seconds=<seconds>` to automatically disable nosleep after a certain time (default is `Inf`, meaning no timeout).

```julia
with_nosleep(; keep_display=true, timeout_seconds=600) do
    # long-running code here
end
```

## Authors

- [Evgeny Metelkin](https://metelkin.me)

## License

MIT (see [LICENSE](LICENSE)).

