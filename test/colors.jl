
rgb24(x::UInt32) = reinterpret(RGB24, x)

@testset "JPEGGray" begin
    @testset "Constructors" begin
        @test JPEGGray{UInt8}(0x00).val === 0x00
        @test JPEGGray8(0xFF).val === 0xFF
        @test JPEGGray16(0x0000).val === 0x0000
        @test JPEGGray(0xFFFF).val === 0xFFFF
        @test JPEGGray(204f0).val === 204.f0

        @test JPEGGray(Gray{Float32}(0.8f0)).val === 204f0
        @test JPEGGray{Float16}(Gray(0.8)).val === Float16(204)
    end

    @testset "Traits" begin
        gray8 = JPEGGray8(Gray(0.6))
        gray16 = JPEGGray16(Gray(0.6))
        grayf32 = JPEGGray{Float32}(Gray(0.6))
        grayf64 = JPEGGray{Float64}(Gray(0.6))

        @test gray(gray8) === 0.6N0f8
        @test gray(gray16) === 0.6N0f16
        @test gray(grayf32) === 0.6f0
        @test gray(grayf64) === 0.6

        @test comp1(gray8) === 153f0
        @test comp1(gray16) === 153f0
        @test comp1(grayf32) === 153f0
        @test comp1(grayf64) === 153.0
    end

    @testset "Display" begin
        @test shown_string(JPEGGray8) == "JPEGGray{UInt8}"
        @test shown_string(JPEGGray8(0x12)) == "JPEGGray8(18)"
        @test shown_string(JPEGGray16(0x1234)) == "JPEGGray16(36.406)"
        @test shown_string(JPEGGray{Float32}(56.7f0)) == "JPEGGray{Float32}(56.7f0)"
    end

    @testset "Conversions" begin
        @test convert(JPEGGray8, RGB{Float64}(0, 0, 0)) === JPEGGray8(0x00)
        @test convert(JPEGGray8, RGB{Float32}(1, 0, 0)) === JPEGGray8(0x4C)
        @test convert(JPEGGray8, RGB{N0f8}(   0, 1, 0)) === JPEGGray8(0x96)
        @test convert(JPEGGray8, RGB{N0f16}(  0, 0, 1)) === JPEGGray8(0x1D)
        @test convert(JPEGGray8, RGB24(       1, 1, 1)) === JPEGGray8(0xFF)
        @test convert(JPEGGray8, rgb24(0xC0FFEE)) === JPEGGray8(0xEA)

        @test convert(JPEGGray16, RGB{Float64}(0, 0, 0)) === JPEGGray16(0x0000)
        @test convert(JPEGGray16, RGB{Float32}(1, 0, 0)) === JPEGGray16(0x261F)
        @test convert(JPEGGray16, RGB{N0f8}(   0, 1, 0)) === JPEGGray16(0x4AD8)
        @test convert(JPEGGray16, RGB{N0f16}(  0, 0, 1)) === JPEGGray16(0x0E89)
        @test convert(JPEGGray16, RGB24(       1, 1, 1)) === JPEGGray16(0x7F80)
        @test convert(JPEGGray16, rgb24(0xC0FFEE)) === JPEGGray16(0x751D)

        @test convert(JPEGGray8, Gray{Float64}(0.8)) === JPEGGray8(0xCC)
        @test convert(JPEGGray8, Gray{N0f8}(   0.4)) === JPEGGray8(0x66)
        @test convert(JPEGGray16, Gray{Float32}(0.8)) === JPEGGray16(0x6600)
        @test convert(JPEGGray16, Gray{N0f8}(   0.4)) === JPEGGray16(0x3300)
    end
end


@testset "JPEGYCbCr" begin
    @testset "Constructors" begin
        @test JPEGYCbCr{UInt8}(0xFF, 0x80, 0x00).y  === 0xFF
        @test JPEGYCbCr{UInt8}(0xFF, 0x80, 0x00).cb === 0x80
        @test JPEGYCbCr{UInt8}(0xFF, 0x80, 0x00).cr === 0x00
        @test JPEGYCbCr8(0x12, 0x34, 0x56).y  === 0x12
        @test JPEGYCbCr8(0x12, 0x34, 0x56).cb === 0x34
        @test JPEGYCbCr8(0x12, 0x34, 0x56).cr === 0x56
        @test JPEGYCbCr16(0xFFFF, 0x8000, 0x0000).y  === 0xFFFF
        @test JPEGYCbCr16(0xFFFF, 0x8000, 0x0000).cb === 0x8000
        @test JPEGYCbCr16(0xFFFF, 0x8000, 0x0000).cr === 0x0000
        @test JPEGYCbCr(0x1234, 0x5678, 0x9ABC).y  === 0x1234
        @test JPEGYCbCr(0x1234, 0x5678, 0x9ABC).cb === 0x5678
        @test JPEGYCbCr(0x1234, 0x5678, 0x9ABC).cr === 0x9ABC
        @test JPEGYCbCr(12.3f0, 45.6f0, -7.89f0).y  === 12.3f0
        @test JPEGYCbCr(12.3f0, 45.6f0, -7.89f0).cb === 45.6f0
        @test JPEGYCbCr(12.3f0, 45.6f0, -7.89f0).cr === -7.89f0
    end

    @testset "Traits" begin
        gray8 = convert(JPEGYCbCr8, Gray(0.6))
        gray16 = convert(JPEGYCbCr16, Gray(0.6))
        grayf32 = convert(JPEGYCbCr{Float32}, Gray(0.6))
        grayf64 = convert(JPEGYCbCr{Float64}, Gray(0.6))

        @test gray(gray8) === 0.6N0f8
        @test gray(gray16) === 0.6N0f16
        @test gray(grayf32) === 0.6f0
        @test gray(grayf64) === 0.6

        @test comp1(gray8) === 153f0
        @test comp1(gray16) === 153f0
        @test comp1(grayf32) === 153f0
        @test comp1(grayf64) === 153.0
        @test comp2(gray8) === 0f0
        @test comp2(gray16) === 0f0
        @test comp2(grayf32) === 0f0
        @test comp2(grayf64) === 0.0
        @test comp3(gray8) === 0f0
        @test comp3(gray16) === 0f0
        @test comp3(grayf32) === 0f0
        @test comp3(grayf64) === 0.0

        blue8 = convert(JPEGYCbCr8, RGB(0, 0, 1))
        blue16 = convert(JPEGYCbCr16, RGB(0, 0, 1))
        bluef32 = convert(JPEGYCbCr{Float32}, RGB(0, 0, 1))
        bluef64 = convert(JPEGYCbCr{Float64}, RGB(0, 0, 1))

        @test comp2(blue8) === 127f0
        @test comp2(blue16) === 127.5f0
        @test comp2(bluef32) === 127.5f0
        @test comp2(bluef64) === 127.5
        @test comp3(blue8) ≈ -21f0
        @test comp3(blue16) ≈ -20.734665f0
        @test comp3(bluef32) ≈ -20.734665f0
        @test comp3(bluef64) ≈ -20.734664916992188
    end

    @testset "Display" begin
        @test shown_string(JPEGYCbCr8) == "JPEGYCbCr{UInt8}"
        @test shown_string(JPEGYCbCr8(0x12, 0x34, 0xAB)) == "JPEGYCbCr8(18,-76,43)"
        @test shown_string(JPEGYCbCr16(0x1234, 0x5678, 0xABCD)) == "JPEGYCbCr16(36.406,172.938,-168.398)"
        @test shown_string(JPEGYCbCr{Float32}(12.3f0, 45.6f0, -7.89f0)) == "JPEGYCbCr{Float32}(12.3f0,45.6f0,-7.89f0)"
    end

    @testset "Conversions" begin
        @test convert(JPEGYCbCr8, RGB{Float64}(0, 0, 0)) === JPEGYCbCr8(0x00, 0x80, 0x80)
        @test convert(JPEGYCbCr8, RGB{Float32}(1, 0, 0)) === JPEGYCbCr8(0x4C, 0x55, 0xFF)
        @test convert(JPEGYCbCr8, RGB{N0f8}(   0, 1, 0)) === JPEGYCbCr8(0x96, 0x2C, 0x15)
        @test convert(JPEGYCbCr8, RGB{N0f16}(  0, 0, 1)) === JPEGYCbCr8(0x1D, 0xFF, 0x6B)
        @test convert(JPEGYCbCr8, RGB24(       1, 1, 1)) === JPEGYCbCr8(0xFF, 0x80, 0x80)
        @test convert(JPEGYCbCr8, rgb24(0xC0FFEE)) === JPEGYCbCr8(0xEA, 0x82, 0x62)

        @test convert(JPEGYCbCr16, RGB{Float64}(0, 0, 0)) === JPEGYCbCr16(0x0000, 0x0000, 0x0000)
        @test convert(JPEGYCbCr16, RGB{Float32}(1, 0, 0)) === JPEGYCbCr16(0x261F, 0xEA7C, 0x3FC0)
        @test convert(JPEGYCbCr16, RGB{N0f8}(   0, 1, 0)) === JPEGYCbCr16(0x4AD8, 0xD5C4, 0xCA9E)
        @test convert(JPEGYCbCr16, RGB{N0f16}(  0, 0, 1)) === JPEGYCbCr16(0x0E89, 0x3FC0, 0xF5A2)
        @test convert(JPEGYCbCr16, RGB24(       1, 1, 1)) === JPEGYCbCr16(0x7F80, 0x0000, 0x0000)
        @test convert(JPEGYCbCr16, rgb24(0xC0FFEE)) === JPEGYCbCr16(0x751D, 0x0111, 0xF0F1)

        @test convert(JPEGYCbCr{Float32}, rgb24(0xC0FFEE)) ≈ JPEGYCbCr{Float32}(234.22499f0, 2.1303558f0, -30.11769f0)

        ycbcr8 = convert(JPEGYCbCr8, rgb24(0xC0FFEE))
        @test convert(RGB24, ycbcr8) === rgb24(0xC0FFEE)

        ycbcr16 = convert(JPEGYCbCr16, rgb24(0xC0FFEE))
        @test convert(RGB24, ycbcr16) === rgb24(0xC0FFEE)

        for h in 0:60:300
            hsv = HSV{Float32}(h, 1, 1)
            ycc = convert(JPEGYCbCr{Float32}, hsv)
            @test ycc isa JPEGYCbCr{Float32}
            @test convert(HSV{Float32}, ycc) ≈ hsv atol=eps(360.0f0)
        end
    end

end
