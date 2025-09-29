# Windows: default API SetThreadExecutionState
const ES_CONTINUOUS        = UInt32(0x80000000)
const ES_SYSTEM_REQUIRED   = UInt32(0x00000001)
const ES_DISPLAY_REQUIRED  = UInt32(0x00000002)

function _nosleep_on(; keep_display::Bool=false)
    flags = ES_CONTINUOUS | ES_SYSTEM_REQUIRED | (keep_display ? ES_DISPLAY_REQUIRED : UInt32(0))
    ccall((:SetThreadExecutionState, "kernel32"), UInt32, (UInt32,), flags)
    return
end

function _nosleep_off()
    ccall((:SetThreadExecutionState, "kernel32"), UInt32, (UInt32,), ES_CONTINUOUS)
    return
end
