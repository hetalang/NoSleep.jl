# NoSleep.jl

[![Autotest](https://github.com/hetalang/NoSleep.jl/actions/workflows/ci.yml/badge.svg)](https://github.com/hetalang/NoSleep.jl/actions/workflows/ci.yml)
[![version](https://juliahub.com/docs/General/NoSleep/stable/version.svg)](https://juliahub.com/ui/Packages/General/NoSleep)
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

using NoSleep
```

## Usage

__Macros style:__

```julia
@nosleep begin
    # long-running code here
end
```

__Block style:__

```julia
with_nosleep() do
    # long-running code here
end
```

__Manual style:__

```julia
nosleep_on()
# long-running code here
nosleep_off()
```

## Extra options

### keep_display

The `keep_display` option prevents the screen from going to sleep (default is `false`).

```julia
@nosleep keep_display=true begin
    # long-running code here
end
```

```julia
with_nosleep(keep_display=true) do
    # long-running code here
end
```

### timeout_seconds (experimental)
The `timeout_seconds` option sets a timeout in seconds after which the nosleep mode is automatically disabled (default is `Inf`, meaning no timeout).

```julia
with_nosleep(; keep_display=true, timeout_seconds=600) do
    # long-running code here
end
```

## Known limitations and recommendations

*Some sleep behaviors are enforced by the operating system and cannot be overridden by NoSleep.jl or any similar tools.*

1. **Closing the laptop lid or pressing the power button** will force the system into sleep regardless of active sleep-prevent requests of `NoSleep.jl`.

1. On Windows devices with **Modern Standby (S0ix) running on battery power (DC mode)** the OS may ignore sleep prevention signals after a 5 minutes of inactivity if the screen is turned off.
    - **Connect charger (AC mode)** to avoid this.
    - **OR use** `keep_display=true` to keep the screen awake.

## Authors

- [Evgeny Metelkin](https://metelkin.me)

## License

MIT (see [LICENSE](LICENSE)).

