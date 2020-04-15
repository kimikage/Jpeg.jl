
"""
    CodeBits

A bit sequence type with a maximum length of 16. Internally this is represented
by a 32-bit integer, with the upper 16 bits representing the length and the
lower 16 bits representing the bit pattern.
"""
struct CodeBits
    data::UInt32
    CodeBits(data::UInt32=zero(UInt32)) = new(data)
    CodeBits(length::Integer, word::Unsigned) =
        new(UInt32(length) << 0x10 | (word & (0xFFFF >> UInt8(0x10 - length))))
end

Base.length(c::CodeBits) = Int((c.data >> 0x10) & 0x1F)
Base.size(c::CodeBits) = (length(c),)

word(c::CodeBits) = unsafe_trunc(UInt16, c.data & 0xFFFF)
inc(c::CodeBits) = CodeBits(UInt32(c.data + 0x1))
shl(c::CodeBits) = CodeBits(length(c) + 1, c.data << 0x1)
isvalid(c::CodeBits) = c.data <= 0x0010FFFF

Base.getindex(c::CodeBits, i::Integer) =
    c.data & (oneunit(UInt32) << UInt8(length(c) - i)) != zero(UInt32)

function Base.iterate(c::CodeBits, state::UInt8=0x0)
    state >= length(c) && return nothing
    state += 0x1
    (c[state], state)
end

function Base.show(io::IO, c::CodeBits)
    bits = isvalid(c) ? string(word(c), base=2, pad=length(c)) : "?"
    print(io, "code\"", bits, "\"")
end

macro code_str(p)
  p == "" ? CodeBits() : CodeBits(length(p), parse(UInt16, p, base=2))
end
