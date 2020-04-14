module LowLevelJPEG

using AbstractTrees
using ColorTypes
using FixedPointNumbers
using StaticArrays

import Base: ==
export Marker, Markers

u8(io::IO) = read(io, UInt8)
u16(io::IO) = ntoh(read(io, UInt16))
u4u4(io::IO) = (b = u8(io); (b >> 0x4, b & 0xF))

hex(x::Unsigned, pad=2length(x)) = string(x, base=16, pad=pad)


include("markers.jl")

end # module
