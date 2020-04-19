import LowLevelJPEG: @code_str

@testset "DCSymbol" begin
    @testset "Constructors" begin
        @test DCSymbol(0x12).bits === UInt8(0x12)
    end

    @testset "Traits" begin
        @test LowLevelJPEG.amplitude(DCSymbol(0x0A)) == 10
    end

    @testset "Display" begin
        @test shown_string(DCSymbol(1)) == "DCSymbol(0x01)"
        @test shown_string([DCSymbol(2), DCSymbol(10)]) == "DCSymbol[0x02, 0x0a]"
    end

    @testset "Conversions" begin
        @test DCSymbol[0x00, 0x01] == [DCSymbol(0x00), DCSymbol(0x01)]
    end
end

@testset "ACSymbol" begin
    @testset "Constructors" begin
        @test ACSymbol(0x12).bits === UInt8(0x12)
        @test ACSymbol(10, 15).bits === UInt8(0xAF)
        @test ACSymbol(10, 0) === LowLevelJPEG.EOB10
    end

    @testset "Traits" begin
        @test LowLevelJPEG.runlength(ACSymbol(10, 15)) == 10
        @test LowLevelJPEG.amplitude(ACSymbol(10, 15)) == 15

        @test LowLevelJPEG.iszrl(LowLevelJPEG.ZRL)
        @test !LowLevelJPEG.iszrl(ACSymbol(10,15))

        @test LowLevelJPEG.iseob(LowLevelJPEG.EOB)
        @test !LowLevelJPEG.iseob(LowLevelJPEG.EOB1)

        @test LowLevelJPEG.iseobn(LowLevelJPEG.EOB)
        @test !LowLevelJPEG.iseobn(LowLevelJPEG.ZRL)
        @test LowLevelJPEG.iseobn(ACSymbol(10,0))
        @test !LowLevelJPEG.iseobn(ACSymbol(10,1))
    end

    @testset "Display" begin
        @test shown_string(ACSymbol(1, 2)) == "ACSymbol(0x12)"
        @test shown_string([ACSymbol(3, 4), ACSymbol(5, 6)]) == "ACSymbol[0x34, 0x56]"
    end

    @testset "Conversions" begin
        @test ACSymbol[0x00, 0x01] == [ACSymbol(0x00), ACSymbol(0x01)]
    end
end

@testset "DCCoeff" begin
    @testset "Constructors" begin
        @test DCCoeff( 0) === DCCoeff(DCSymbol(0x00), code"")
        @test DCCoeff(-1) === DCCoeff(DCSymbol(0x01), code"0")
        @test DCCoeff(+1) === DCCoeff(DCSymbol(0x01), code"1")
        @test DCCoeff(-3) === DCCoeff(DCSymbol(0x02), code"00")
        @test DCCoeff(-2) === DCCoeff(DCSymbol(0x02), code"01")
        @test DCCoeff(+2) === DCCoeff(DCSymbol(0x02), code"10")
        @test DCCoeff(+3) === DCCoeff(DCSymbol(0x02), code"11")
        @test DCCoeff(-2047) === DCCoeff(DCSymbol(0x0B), code"00000000000")
        @test DCCoeff(+2047) === DCCoeff(DCSymbol(0x0B), code"11111111111")

        # for 12-bit sample precision
        @test DCCoeff(-32767) === DCCoeff(DCSymbol(0x0F), code"000000000000000")
        @test DCCoeff(+32767) === DCCoeff(DCSymbol(0x0F), code"111111111111111")
    end

    @testset "Display" begin
        @test shown_string(DCCoeff(-10)) == "DCCoeff(-10)"
        @test shown_string(DCTCoeff[DCCoeff(0), DCCoeff(1)]) ==
            "DCTCoeff[DCCoeff(0), DCCoeff(1)]"
        @test shown_string([DCCoeff(-1), DCCoeff(2)]) ==
            "DCTCoeff{DCSymbol}[-1, 2]"
        @test shown_plaintext([DCCoeff(-1), DCCoeff(2)]) ==
            """
            2-element Array{DCTCoeff{DCSymbol},1}:
             -1
             2"""
    end

    @testset "Conversions" begin
        @test all(v -> Int(DCCoeff(v)) == v, -2047:2047)
    end
end

@testset "ACCoeff" begin
    @testset "Constructors" begin
        @test ACCoeff(0) === ACCoeff(ACSymbol(0x00), code"") # EOB

        @test ACCoeff(-1) === ACCoeff(ACSymbol(0x01), code"0")
        @test ACCoeff(+1) === ACCoeff(ACSymbol(0x01), code"1")
        @test ACCoeff(-3) === ACCoeff(ACSymbol(0x02), code"00")
        @test ACCoeff(-2) === ACCoeff(ACSymbol(0x02), code"01")
        @test ACCoeff(+2) === ACCoeff(ACSymbol(0x02), code"10")
        @test ACCoeff(+3) === ACCoeff(ACSymbol(0x02), code"11")
        @test ACCoeff(-1023) === ACCoeff(ACSymbol(0x0A), code"0000000000")
        @test ACCoeff(+1023) === ACCoeff(ACSymbol(0x0A), code"1111111111")

        @test ACCoeff(-4, 5) === ACCoeff(ACSymbol(0x53), code"011")

        # fixes amplitude
        @test ACCoeff(4, ACSymbol(0xAA)) === ACCoeff(ACSymbol(0xA3), code"100")

        # EOBn
        @test ACCoeff(5, LowLevelJPEG.EOB2) === ACCoeff(ACSymbol(0x20), code"01")
        @test ACCoeff(16384, LowLevelJPEG.EOB14) === ACCoeff(ACSymbol(0xE0), code"00000000000000")
        @test ACCoeff(32767, LowLevelJPEG.EOB14) === ACCoeff(ACSymbol(0xE0), code"11111111111111")
        # the result symbol will be fixed to the proper EOBn.
        @test ACCoeff(7, LowLevelJPEG.EOB) === ACCoeff(LowLevelJPEG.EOB2, code"11")
    end

    @testset "Traits" begin
        @test length(ACCoeff(5, 15)) == 16
        @test length(ACCoeff(5, LowLevelJPEG.EOB4)) == 0
    end

    @testset "Display" begin
        @test shown_string(ACCoeff(-10)) == "ACCoeff(-10)"
        @test shown_string(ACCoeff(-10, 2)) == "ACCoeff(-10, 2)"
        @test shown_plaintext(ACCoeff(-10, 2)) ==   """
                                                    3-element DCTCoeff{ACSymbol}:
                                                     0
                                                     0
                                                     -10"""
        @test shown_string(ACCoeff(0)) == "ACCoeff(1, EOB)"
        @test shown_plaintext(ACCoeff(10, LowLevelJPEG.EOB)) ==
            "DCTCoeff{ACSymbol}(10, EOB3)"
        @test shown_string([ACCoeff(10, LowLevelJPEG.EOB), ACCoeff(1,5)]) ===
            "DCTCoeff{ACSymbol}[ACCoeff(10, EOB3), ACCoeff(1, 5)]"
        @test shown_plaintext([ACCoeff(10, LowLevelJPEG.EOB) ACCoeff(1,5)]) ===
            """
            1×2 Array{DCTCoeff{ACSymbol},2}:
             ACCoeff(10, EOB3)  ACCoeff(1, 5)"""
    end

    @testset "Conversions" begin
        @test all(v -> Int(ACCoeff(v, 1)) == v || v == 0, -1023:1023)
        @test all(v -> Int(ACCoeff(v, LowLevelJPEG.EOB)) == v, 1:1024)
    end
end
