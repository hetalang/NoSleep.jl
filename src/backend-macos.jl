# macOS: default keep-awake through `caffeinate` utility.
# (In the future, ccall to IOKit: IOPMAssertionCreateWithName can be added)

const _backend_name = "macos:caffeinate"
const _nosleep_proc_ref = Ref{Base.Process}()

function _have_caffeinate()
    Sys.which("caffeinate") !== nothing
end

function _nosleep_on(; keep_display::Bool=false)
    if !_have_caffeinate()
        @warn "caffeinate not found; no-sleep may not work. Using stub."
        return
    end
    # -d keeps display awake, -i keeps system from idle sleep
    flags = keep_display ? `-di` : `-i`
    cmd = `caffeinate $flags`
    if isnothing(_nosleep_proc_ref[])
        _nosleep_proc_ref[] = run(cmd; wait=false)
    end
    return
end

function _nosleep_off()
    p = _nosleep_proc_ref[]
    if p isa Base.Process
        try
            kill(p)
        catch
        end
        _nosleep_proc_ref[] = nothing
    end
    return
end
