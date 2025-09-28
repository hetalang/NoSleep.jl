const _backend_name = "unsupported-os"

function _nosleep_on(; keep_display::Bool=false)
    @warn "NoSleep.jl: current OS is not supported; using stub."
end

function _nosleep_off()
    # nothing
end
