# NoSleep.jl

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

## License

MIT (see [LICENSE](LICENSE)).

