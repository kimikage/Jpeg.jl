import LowLevelJPEG: @code_str

@testset "Constructors" begin
    @test CodeBits() == CodeBits(0, 0x1)
    @test CodeBits(0x0006000D).data === 0x6000D
    @test CodeBits(6, 0b001101).data === 0x6000D
    @test CodeBits(0, 0b001101).data === 0x00000
end

@testset "Traits" begin
    @test LowLevelJPEG.word(code"001101") === UInt16(0b001101)
    @test LowLevelJPEG.isvalid(code"1000100010001000")
    @test !LowLevelJPEG.isvalid(CodeBits(0x10000000))
    @test length(code"") == 0
    @test length(code"001101") == 6
    @test size(code"001101") == (6,)

    @test code"01"[1] == false
end

@testset "Display" begin
    @test shown_string(code"") == "code\"\""
    @test shown_string(code"001101") == "code\"001101\""
    @test shown_string(CodeBits(0x11FFFF)) == "code\"?\""
end

@testset "Functions" begin
    @test LowLevelJPEG.inc(code"001101") === code"001110"
    @test LowLevelJPEG.shl(code"001101") === code"0011010"

    @test BitArray(code"001101") == BitArray((0, 0, 1, 1, 0, 1))
end
