
@testset "Constructors" begin
    qt8 = QuantizationTable8(1:64, id=1)
    @test qt8.id === 0x1
    @test all(i -> qt8[i] === UInt8(i), 1:64)
    @test qt8[3, 2] === 0x9

    qt8c = QuantizationTable8(qt8, id=2)
    @test qt8c.id === 0x2
    @test qt8c.table == qt8.table

    @test_throws ErrorException QuantizationTable8(1:64, id=4)
    @test_throws DimensionMismatch QuantizationTable8(1:65)

    qt16 = QuantizationTable16([x * y for y = 1:8, x = 1:8])
    @test qt16.id === 0x0
    @test qt16[3, 4] === UInt16(12)
end

@testset "Traits" begin
    qt8 = QuantizationTable8(1:64)
    @test sizeof(QuantizationTable8) == 65
    @test sizeof(qt8) == 65
    @test length(qt8) == 64
    @test size(qt8) == (8, 8)

    qt16 = QuantizationTable16(1:64, id=1)
    @test sizeof(QuantizationTable16) == 129
    @test sizeof(qt16) == 129
    @test length(qt16) == 64
    @test size(qt16) == (8, 8)
end

@testset "Display" begin
    qt = readtest(QuantizationTable, 0x18)
    @test shown_string(qt) ==   "QuantizationTable8([" *
                                "5 5 5 5 8 11 17 26; " *
                                "5 5 6 8 10 12 16 23; " *
                                "5 6 7 9 13 19 27 41; " *
                                "5 8 9 12 16 22 32 47; " *
                                "8 10 13 16 21 28 39 57; " *
                                "11 12 19 22 28 37 51 71; " *
                                "17 16 27 32 39 51 68 93; " *
                                "26 23 41 47 57 71 93 125], id=0)"
    @test shown_plaintext(qt) ==   """
                                8×8 8-bit QuantizationTable{UInt8}(id=0):
                                    5    5    5    5    8   11   17   26
                                    5    5    6    8   10   12   16   23
                                    5    6    7    9   13   19   27   41
                                    5    8    9   12   16   22   32   47
                                    8   10   13   16   21   28   39   57
                                   11   12   19   22   28   37   51   71
                                   17   16   27   32   39   51   68   93
                                   26   23   41   47   57   71   93  125"""
end
@testset "Functions" begin
    qt = readtest(QuantizationTable, 0x59)
    @test qt.id === 0x1
    @test qt isa QuantizationTable8
    @test qt[1] === UInt8(5)
    @test qt[1, 8] == UInt8(26)

    @test_throws ErrorException readtest(QuantizationTable16, 0x59)

    qt16 = QuantizationTable16(0x1A0:0x1DF, id=0x03)
    @test written_hex(qt16) ==  "13" *
                                "01a001a101a201a301a401a501a601a7" *
                                "01a801a901aa01ab01ac01ad01ae01af" *
                                "01b001b101b201b301b401b501b601b7" *
                                "01b801b901ba01bb01bc01bd01be01bf" *
                                "01c001c101c201c301c401c501c601c7" *
                                "01c801c901ca01cb01cc01cd01ce01cf" *
                                "01d001d101d201d301d401d501d601d7" *
                                "01d801d901da01db01dc01dd01de01df"
end
