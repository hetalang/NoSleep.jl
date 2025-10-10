# Windows: default PowerRequest API (powrprof.dll)
# Prevents Modern Standby (S0ix) sleep reliably without polling

const PowerRequestDisplayRequired = UInt32(0)
const PowerRequestSystemRequired = UInt32(1)
#const PowerRequestAwayModeRequired = UInt32(2)
#const PowerRequestExecutionRequired = UInt32(3)

# C equivalent:
# typedef struct _REASON_CONTEXT {
#   ULONG Version;
#   DWORD Flags;
#   union { LPWSTR SimpleReasonString; ... };
# } REASON_CONTEXT;
struct ReasonContext
    Version::UInt32
    Flags::UInt32
    SimpleReasonString::Ptr{UInt16}  # LPWSTR
end

const REASON_CONTEXT_VERSION = UInt32(0)
const POWER_REQUEST_CONTEXT_SIMPLE_STRING = UInt32(0x1)

# globals
const _g_req_handle = Ref{Ptr{Cvoid}}(C_NULL) # Pointer to the power request handle, C_NULL if no handle
const _g_req_display = Ref{Bool}(false) # Pointer to the display request state, true if display request is active

function _nosleep_on(; keep_display::Bool=false)
    reason = "Set by user with NoSleep.jl\0" # (UTF-16, NUL-terminated)

    # Create the request handle if not existing
    if _g_req_handle[] == C_NULL
        # Prepare simple reason string 
        wreason = Vector{UInt16}(codeunits(reason))  # no copy on ccall argument
        context = ReasonContext(
            REASON_CONTEXT_VERSION,
            POWER_REQUEST_CONTEXT_SIMPLE_STRING,
            pointer(wreason)
        )
        h = ccall(
            (:PowerCreateRequest, "kernel32"), Ptr{Cvoid}, # "powrprof"
            (Ref{ReasonContext},), 
            context
        )
        h == C_NULL && error("PowerCreateRequest failed")
        
        _g_req_handle[] = h
    end

    # Activate system-required request
    status = ccall( # > 0 on success
        (:PowerSetRequest, "kernel32"), UInt8, # "powrprof"
        (Ptr{Cvoid}, UInt32), 
        _g_req_handle[], PowerRequestSystemRequired
    )
    status == 0 && error("PowerSetRequest(SystemRequired) failed")

    # Optionally keep the display on
    if keep_display && !_g_req_display[]
        # okd = _power_set_request(_g_req_handle[], PowerRequestDisplayRequired)
        status = ccall( # > 0 on success
            (:PowerSetRequest, "kernel32"), UInt8, # "powrprof"
            (Ptr{Cvoid}, UInt32), 
            _g_req_handle[], PowerRequestDisplayRequired
        )
        status == 0 && error("PowerSetRequest(DisplayRequired) failed")
        _g_req_display[] = true
    end

    return
end

function _nosleep_off()
    h = _g_req_handle[] # get current handle
    h == C_NULL && return # if no handle, break early

    # Clear power request
    ccall( # > 0 on success
        (:PowerClearRequest, "kernel32"), UInt8, # "powrprof" 
        (Ptr{Cvoid}, UInt32), 
        h, PowerRequestSystemRequired
    )

    # get current display
    if _g_req_display[]
        ccall( # > 0 on success
            (:PowerClearRequest, "kernel32"), UInt8, # "powrprof" 
            (Ptr{Cvoid}, UInt32), 
            h, PowerRequestDisplayRequired
        )
        _g_req_display[] = false # set as inactive
    end

    # Close handle
    ccall( # > 0 on success
        (:CloseHandle, "kernel32"), UInt8, 
        (Ptr{Cvoid},),
        h
    )

    # Clean handle
    _g_req_handle[] = C_NULL 
    
    return
end
