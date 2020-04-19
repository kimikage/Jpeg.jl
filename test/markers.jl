
@testset "Constants" begin
    @test Markers.SOI === 0xFFD8
end

@testset "Constructors" begin
    @test_throws ErrorException Marker(0xCAFE)
    @test Marker(0xFF01) === Marker{0xFF01}()
end

@testset "Operators" begin
    @test Marker{:SOF1}() !== Marker{0xFFC1}()
    @test Marker{:SOF1}() == Marker{0xFFC1}()
end

@testset "Traits" begin
    @test sizeof(Marker{:JPG0}) == 2
    @test sizeof(Marker{:JPG0}()) == 2
end

@testset "Display" begin
    @test shown_string(Marker{:SOI}) == "Marker{:SOI}"
    @test shown_string(LowLevelJPEG.SOI) == "Marker{:SOI}()"
end

@testset "Functions" begin
    @test written_hex(LowLevelJPEG.EOI) == "ffd9"

    @test reinterpret(UInt16, Marker{:SOF0}()) == 0xFFC0
end
