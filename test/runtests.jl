using Test
using NoSleep

@testset "NoSleep.jl basic API" begin
    # backend name must be a String
    @test isa(NoSleep.backend_name(), String)

    # on/off should run without error
    @test_nowarn NoSleep.nosleep_on()
    @test_nowarn NoSleep.nosleep_off()

    # with_nosleep should execute block and return result
    result = with_nosleep() do
        2 + 2
    end
    @test result == 4

    # with_nosleep must restore state even if exception is thrown
    try
        with_nosleep() do
            error("fail inside block")
        end
    catch e
        @test isa(e, ErrorException)
    end
    # after exception nosleep_off should still be callable
    @test_nowarn NoSleep.nosleep_off()
end

@testset "NoSleep.jl @nosleep macro" begin
    # @nosleep should execute block and return result
    result = @nosleep begin
        3 * 3
    end
    @test result == 9

    # @nosleep must restore state even if exception is thrown
    try
        @nosleep begin
            error("fail inside macro block")
        end
    catch e
        @test isa(e, ErrorException)
    end
    # after exception nosleep_off should still be callable
    @test_nowarn NoSleep.nosleep_off()
end

@testset "NoSleep.jl keep_display option" begin
    # nosleep_on with keep_display=true should run without error
    @test_nowarn NoSleep.nosleep_on(keep_display=true)
    @test_nowarn NoSleep.nosleep_off()
end
