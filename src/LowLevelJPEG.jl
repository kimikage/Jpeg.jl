module LowLevelJPEG

using AbstractTrees
using ColorTypes
using FixedPointNumbers
using StaticArrays

u8(io::IO) = read(io, UInt8)
u16(io::IO) = ntoh(read(io, UInt16))
u4u4(io::IO) = (b = u8(io); (b >> 0x4, b & 0xF))

end # module
