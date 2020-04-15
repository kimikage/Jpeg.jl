import LowLevelJPEG: @code_str, getcodeindex

@testset "HuffmanTreeNode" begin
    @testset "Constructors" begin
        snode1 = HuffmanTreeNode((ACSymbol(0x1), 0.5))
        @test snode1 === HuffmanSymbolNode(ACSymbol(0x1), 0.5)

        snode2 = ACSymbolNode(0x02, 0.25)
        @test snode2 === ACSymbolNode(ACSymbol(0x02), 0.25)

        bnode = HuffmanTreeNode((snode1, snode2))
        @test bnode === HuffmanBranchNode(snode1, snode2)
        @test bnode.probability === 0.75

        @test HuffmanTreeNode((DCSymbol(0x1), 0.5)) ===
                HuffmanSymbolNode(DCSymbol(0x1), 0.5)
    end
end

@testset "HuffmanTree" begin
    s2 = HuffmanTreeNode{ACSymbol}[
        (ACSymbol(0x01), 0.6),
        (ACSymbol(0x02), 0.4)
    ]
    s6 = HuffmanTreeNode{ACSymbol}[
        (0x01, 0.5),
        (0x02, 0.2),
        (0x03, 0.1),
        (0x04, 0.09),
        (0x05, 0.08),
        (0x06, 0.03)
    ]

    @testset "Constructors" begin
        h2 = HuffmanTree(s2)
        @test h2 isa ACHuffmanTree

        h1 = HuffmanTree([HuffmanSymbolNode(DCSymbol(0x1), 1.0)])
        @test h1 isa DCHuffmanTree

        @test_throws MethodError HuffmanTree([])
        @test_throws ErrorException HuffmanTree(HuffmanSymbolNode{ACSymbol}[])
    end

    @testset "Traits" begin
        h2 = HuffmanTree(s2)
        @test LowLevelJPEG.height(h2) == 1
        h6 = HuffmanTree(s6)
        @test LowLevelJPEG.height(h6) == 4
    end

    @testset "Display" begin
        h6 = HuffmanTree(s6)
        @test shown_string(h6) ==   "HuffmanTree{ACSymbol}(" *
                                        "("*"(0x01, 0.5), " *
                                            "("*"("*"("*"(0x03, 0.1), " *
                                                        "(0x04, 0.09)), " *
                                                    "("*"(0x05, 0.08), " *
                                                        "(0x06, 0.03))), " *
                                                "(0x02, 0.2))))"

        @test shown_plaintext(h6) ==    """
                                        HuffmanTree{ACSymbol}
                                        ├─ ACSymbolNode(0x01, 0.5)
                                        └─ ・
                                           ├─ ・
                                           │  ├─ ・
                                           │  │  ├─ ACSymbolNode(0x03, 0.1)
                                           │  │  └─ ACSymbolNode(0x04, 0.09)
                                           │  └─ ・
                                           │     ├─ ACSymbolNode(0x05, 0.08)
                                           │     └─ ACSymbolNode(0x06, 0.03)
                                           └─ ACSymbolNode(0x02, 0.2)"""
    end

    @testset "Conversions" begin
        h6 = HuffmanTree(s6)
        htable = HuffmanTable(h6)
        @test htable isa ACHuffmanTable
        h6r = HuffmanTree(htable)
        @test shown_plaintext(h6r) ==  """
                                    HuffmanTree{ACSymbol}
                                    ├─ ACSymbolNode(0x01, 0.5)
                                    └─ ・
                                       ├─ ACSymbolNode(0x02, 0.25)
                                       └─ ・
                                          ├─ ・
                                          │  ├─ ACSymbolNode(0x03, 0.0625)
                                          │  └─ ACSymbolNode(0x04, 0.0625)
                                          └─ ・
                                             ├─ ACSymbolNode(0x05, 0.0625)
                                             └─ ACSymbolNode(0x06, 0.0625)"""

    end
end

@testset "HuffmanTable" begin

    @testset "Constructors" begin
        li = fill(0x0, 16)
        li[2] = 1
        li[4] = 2
        dcsymbols = DCSymbol.(0x1:0x3)
        acsymbols = ACSymbol.(0x2:0x4)

        dcht = DCHuffmanTable(li, dcsymbols)
        @test dcht isa DCHuffmanTable
        @test dcht.id === 0x0

        acht = ACHuffmanTable(li, acsymbols, id=0x1)
        @test acht isa ACHuffmanTable
        @test acht.id === 0x1
    end

    @testset "Traits" begin
        dcht = readtest(HuffmanTable, 0xB1)
        @test sizeof(dcht) == 21
        @test length(dcht) == 4
        @test LowLevelJPEG.codelist(dcht) == [code"00", code"01", code"10", code"110"]
    end

    @testset "Display" begin
        dcht = readtest(HuffmanTable, 0xB1)
        @test shown_string(dcht) ==
            "HuffmanTable{DCSymbol}(" *
            "[0, 3, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0], " *
            "DCSymbol[0x00, 0x05, 0x07, 0x08], id=0)"
        @test shown_plaintext(dcht) == """
                                    4-symbol HuffmanTable{DCSymbol}(id=0):
                                     DCSymbol(0x00)  code"00"
                                     DCSymbol(0x05)  code"01"
                                     DCSymbol(0x07)  code"10"
                                     DCSymbol(0x08)  code"110\""""
    end
end

@testset "HuffmanDecoder" begin

    ht = ACHuffmanTable(UInt8[0, 1, 2, 3, 0, 0, 0, 0, 1, 1, 1, 1, 1, 0, 0, 1],
                        ACSymbol.(0x01:0x0C), id=0x0)
    @test shown_plaintext(ht) ==   """
                                12-symbol HuffmanTable{ACSymbol}(id=0):
                                 ACSymbol(0x01)  code"00"
                                 ACSymbol(0x02)  code"010"
                                 ACSymbol(0x03)  code"011"
                                 ACSymbol(0x04)  code"1000"
                                 ACSymbol(0x05)  code"1001"
                                 ACSymbol(0x06)  code"1010"
                                 ACSymbol(0x07)  code"101100000"
                                 ACSymbol(0x08)  code"1011000010"
                                 ACSymbol(0x09)  code"10110000110"
                                 ACSymbol(0x0a)  code"101100001110"
                                 ACSymbol(0x0b)  code"1011000011110"
                                 ACSymbol(0x0c)  code"1011000011111000\""""

    @testset "Constructors" begin
        @test LowLevelJPEG.HuffmanDecoder(ht) isa LowLevelJPEG.HuffmanDecoder
    end

    @testset "Functions" begin
        d = LowLevelJPEG.HuffmanDecoder(ht)
        @test getcodeindex(d, UInt32(0b0101010101010101) << 16, 2) == 0
        @test getcodeindex(d, UInt32(0b0101010101010101) << 16, 3) == 2
        @test getcodeindex(d, UInt32(0b0101010101010101) << 16, 4) == 2
        @test_throws LowLevelJPEG.BitSequenceError getcodeindex(
            d, UInt32(0b1111111100000000) << 16, 8)
        @test getcodeindex(d, UInt32(0b1011000011111000) << 16, 15) == 0
        @test getcodeindex(d, UInt32(0b1011000011111000) << 16, 16) == 12
        @test getcodeindex(d, UInt32(0b1011000011111000) << 16, 17) == 12
        @test_throws LowLevelJPEG.BitSequenceError getcodeindex(
            d, UInt32(0b1011000011111001) << 16, 16)
    end
end
