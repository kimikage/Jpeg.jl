module LowLevelJPEG

using AbstractTrees
using ColorTypes
using FixedPointNumbers
using StaticArrays

import Base: ==
export JPEGGray, JPEGGray8, JPEGGray16, JPEGYCbCr, JPEGYCbCr8, JPEGYCbCr16,
       Marker, Markers,
       CodeBits,
       DCSymbol, ACSymbol, DCTCoeff, DCCoeff, ACCoeff,
       DCTBlock,
       QuantizationTable, QuantizationTable8, QuantizationTable16,
       quantize, dequantize,
       HuffmanTreeNode, HuffmanBranchNode,
       HuffmanSymbolNode, DCSymbolNode, ACSymbolNode,
       HuffmanTree, DCHuffmanTree, ACHuffmanTree,
       HuffmanTable, DCHuffmanTable, ACHuffmanTable

u8(io::IO) = read(io, UInt8)
u16(io::IO) = ntoh(read(io, UInt16))
u4u4(io::IO) = (b = u8(io); (b >> 0x4, b & 0xF))

hex(x::Unsigned, pad=2length(x)) = string(x, base=16, pad=pad)

include("colors.jl")
include("markers.jl")
include("codebits.jl")
include("coeffs.jl")
include("blocks.jl")
include("qt.jl")
include("huffman.jl")

end # module
