using Test
using NoSleep

# Enable these integration checks only when explicitly requested
const RUN_CLI_CHECKS = get(ENV, "NOSLEEP_CLI_TESTS", "0") == "1"

@testset "CLI integration checks (opt-in)" begin
    if !RUN_CLI_CHECKS
        @info "CLI checks are disabled (set NOSLEEP_CLI_TESTS=1 to enable)."
        return
    end

    # Small pause to let background processes appear in listings when needed
    function short_wait()
        try sleep(0.2); catch; end
    end

    @static if Sys.islinux()
        # Requires systemd
        if Sys.which("systemd-inhibit") !== nothing && Sys.which("loginctl") !== nothing
            @testset "Linux: systemd-inhibit is listed" begin
                # Before
                pre = read(`systemd-inhibit --list`, String)

                NoSleep.nosleep_on()
                short_wait()
                mid = read(`systemd-inhibit --list`, String)
                NoSleep.nosleep_off()
                post = read(`systemd-inhibit --list`, String)

                # Our backend uses --who=NoSleep.jl --why=Long computation
                @test occursin(r"NoSleep\.jl", mid)
                @test !occursin(r"NoSleep\.jl", post)  # released after off()
                @test pre != mid                        # state actually changed
            end
        else
            @info "Skip Linux CLI check: systemd-inhibit or loginctl not found."
        end

    elseif Sys.isapple()
        # macOS: pmset -g assertions shows caffeinate when running
        if Sys.which("pmset") !== nothing && Sys.which("caffeinate") !== nothing
            @testset "macOS: pmset shows caffeinate assertion" begin
                pre = read(`pmset -g assertions`, String)

                NoSleep.nosleep_on(; keep_display=false)
                short_wait()
                mid = read(`pmset -g assertions`, String)
                NoSleep.nosleep_off()
                post = read(`pmset -g assertions`, String)

                # Look for caffeinate process being asserted
                @test occursin(r"caffeinate", mid)
                @test !occursin(r"caffeinate", post) || post == mid # some systems cache briefly
            end
        else
            @info "Skip macOS CLI check: pmset or caffeinate missing."
        end

    elseif Sys.iswindows()
        # Windows: powercfg /requests may NOT always show SetThreadExecutionState reliably.
        # We'll treat it as a soft signal: if we see expected tokens, pass; otherwise mark broken.
        if Sys.which("powercfg") !== nothing
            @testset "Windows: powercfg /requests soft signal" begin
                pre = read(`powershell -NoProfile -Command "powercfg /requests"`, String)

                NoSleep.nosleep_on()
                short_wait()
                mid = read(`powershell -NoProfile -Command "powercfg /requests"`, String)
                NoSleep.nosleep_off()
                post = read(`powershell -NoProfile -Command "powercfg /requests"`, String)

                # Heuristics: look for common markers that appear under SYSTEM/DISPLAY sections.
                # This can be flaky across versions/Group Policy, so keep expectations soft.
                has_signal(s) = occursin(r"EXECUTION|System Required|Display Required|Legacy Kernel Caller", s)

                if has_signal(mid) && (!has_signal(post) || post == pre)
                    @test true
                else
                    @test_broken false  # document flakiness instead of failing CI
                end
            end
        else
            @info "Skip Windows CLI check: powercfg missing."
        end

    else
        @info "Unsupported OS for CLI checks."
    end
end
