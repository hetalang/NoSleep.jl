# macOS: default keep-awake through `caffeinate` utility.
# (Future: switch to IOPMAssertion via ccall for even tighter control.)

const _nosleep_proc_ref = Ref{Union{Nothing, Base.Process}}(nothing)

_have_caffeinate() = Sys.which("caffeinate") !== nothing

# small helper: robustly terminate a process without blocking forever
function _terminate!(p::Base.Process; grace_ms::Int=500)
    try
        # First try a graceful TERM
        kill(p)  # SIGTERM
        # Poll for a short grace period
        steps = max(1, div(grace_ms, 50))
        for _ in 1:steps
            # `process_running` returns false when the process has exited
            if !Base.process_running(p)
                return
            end
            sleep(0.05)
        end
        # If still alive, use SIGKILL
        kill(p, 9)
    catch
        # Ignore teardown errors
    end
end

function _nosleep_on(; keep_display::Bool=false)
    if !_have_caffeinate()
        @warn "caffeinate not found; no-sleep may not work. Using stub."
        return
    end

    # Cleanup a dead/finished process in the ref, if any
    current = _nosleep_proc_ref[]
    if current isa Base.Process && !Base.process_running(current)
        _nosleep_proc_ref[] = nothing
        current = nothing
    end

    if isnothing(current)
        # Use a long but finite timeout so the runner won't be stuck forever if teardown fails
        # -i : prevent idle sleep, -d : also keep display awake when requested
        # -t : seconds; pick something long enough for typical CI runs (e.g., 2 hours)
        timeout_sec = 7200
        cmd = keep_display ? `caffeinate -d -i -t $timeout_sec` : `caffeinate -i -t $timeout_sec`
        # Start detached; don't wait
        _nosleep_proc_ref[] = run(cmd; wait=false)
    end
    return
end

function _nosleep_off()
    p = _nosleep_proc_ref[]
    if p isa Base.Process
        if Base.process_running(p)
            _terminate!(p; grace_ms=800)  # short grace, then SIGKILL
        end
        # do NOT call wait(p) here; just clear the ref
        _nosleep_proc_ref[] = nothing
    end
    return
end
