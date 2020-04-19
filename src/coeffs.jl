
abstract type SourceSymbol end

struct DCSymbol <: SourceSymbol
    bits::UInt8
end

struct ACSymbol <: SourceSymbol
    bits::UInt8
    ACSymbol(bits::UInt8) = new(bits)
    ACSymbol(run::Integer, amp::Integer) = new(run << 0x4 | (amp & 0x0F))
end
const ZRL = ACSymbol(0xF0)
const EOB = ACSymbol(0x00)
const EOB0 =  ACSymbol(0x00)
const EOB1 =  ACSymbol(0x10)
const EOB2 =  ACSymbol(0x20)
const EOB3 =  ACSymbol(0x30)
const EOB4 =  ACSymbol(0x40)
const EOB5 =  ACSymbol(0x50)
const EOB6 =  ACSymbol(0x60)
const EOB7 =  ACSymbol(0x70)
const EOB8 =  ACSymbol(0x80)
const EOB9 =  ACSymbol(0x90)
const EOB10 = ACSymbol(0xA0)
const EOB11 = ACSymbol(0xB0)
const EOB12 = ACSymbol(0xC0)
const EOB13 = ACSymbol(0xD0)
const EOB14 = ACSymbol(0xE0)

amplitude(s::DCSymbol) = s.bits
amplitude(s::ACSymbol) = s.bits & 0x0F
runlength(s::ACSymbol) = s.bits >> 0x4
iszrl(s::ACSymbol) = s.bits === 0xF0
iseob(s::ACSymbol) = s.bits === 0x00
iseobn(s::ACSymbol) = (s.bits & 0x0F === 0x00) & (s.bits < 0xF0)

function Base.show(io::IO, s::T) where T <: Union{DCSymbol, ACSymbol}
    if get(io, :typeinfo, Any) === T
        print(io, "0x", hex(s.bits))
    else
        print(io, T, "(0x", hex(s.bits), ")")
    end
end

Base.convert(T::Type{<:SourceSymbol}, bits::UInt8) = T(bits)

"""
    DCTCoeff{T}

A type for the intermediate representation of quantized DCT coefficients.
See also [`DCCoeff`](@ref) and [`ACCoeff`](@ref).
"""
struct DCTCoeff{T<:SourceSymbol}
    symbol::T
    data::CodeBits
end

const DCCoeff = DCTCoeff{DCSymbol}
const ACCoeff = DCTCoeff{ACSymbol}

"""
    DCCoeff(v)

Create a DC coefficient with value of `v`.
"""
function DCCoeff(v::Integer)
    c = encode_coeff(v)
    DCCoeff(DCSymbol(length(c)), c)
end

"""
    ACCoeff(v, run::Integer=0)
    ACCoeff(v, s::ACSymbol)

Create an AC coefficient with value of `v`.
"""
function ACCoeff(v::Integer, run::Integer=0)
    c = encode_coeff(v)
    ACCoeff(ACSymbol(run, length(c)), c)
end
function ACCoeff(v::Integer, s::ACSymbol)
    if iseobn(s)
        c = encode_eoblength(v)
        ACCoeff(ACSymbol(length(c), 0), c)
    else
        c = encode_coeff(v)
        ACCoeff(ACSymbol(runlength(s), length(c)), c)
    end
end

# 0 => length=0
# -1, 1 => length=1
# -3:-2, 2:3 => length=2
# -7:-4, 4:7 => length=3
const N_DIGITS = SVector{256, Int}([ceil(log2(i)) for i = 1:256])

function encode_coeff(v::Integer)
    n = abs(v)
    @inbounds len = n < 256 ? N_DIGITS[n + 1] : N_DIGITS[n >> 0x8 + 1] + 8
    bits = unsafe_trunc(UInt16, v < 0 ? v - 1 : v)
    CodeBits(len, bits)
end
function decode_coeff(c::CodeBits)
    len = length(c)
    len == 0 && return zero(Int16)
    mask = (0xFFFF >> UInt8(len) << UInt8(len)) + 0x001
    signed(word(c) + ifelse(c[1], 0x0000, mask))
end
function encode_eoblength(v::Integer)
    n = max(v, oneunit(v))
    @inbounds len = n < 256 ? N_DIGITS[n + 1] : N_DIGITS[n >> 0x8 + 1] + 8
    CodeBits(len - 1,  unsafe_trunc(UInt16, v))
end
function decode_eoblength(c::CodeBits)
    signed(0x0001 << UInt8(length(c)) + word(c))
end

"""
    length(coeff::ACCoeff)

Return the length of coefficients with the run-length of zero coefficients.

!!! note
    Since EOB and EOBn have no finite length of coefficients, this method
    returns `0` and does not throw errors.
    If you want to get the length of bands which have an end-of-band, convert
    an ACCoeff with EOBn to `Signed`, e.g. ```Int(coeff)```.
"""
function Base.length(coeff::ACCoeff)
    iseobn(coeff.symbol) && return 0
    iszrl(coeff.symbol) && return 15
    runlength(coeff.symbol) + 1
end

function Base.getindex(coeff::ACCoeff, i::Integer)
    length(coeff) == i && return Int(coeff)
    zero(i)
end
function Base.iterate(coeff::ACCoeff, state::Int=0)
    state >= length(coeff) && return nothing
    state += 1
    (coeff[state], state)
end

function Base.convert(::Type{T}, coeff::DCCoeff) where T <: Signed
    convert(T, decode_coeff(coeff.data))
end
function Base.convert(::Type{T}, coeff::ACCoeff) where T <: Signed
    if iseobn(coeff.symbol)
        convert(T, decode_eoblength(coeff.data))
    else
        convert(T, decode_coeff(coeff.data))
    end
end

(::Type{T})(coeff::DCTCoeff) where T <: Signed = convert(T, coeff)


function Base.show(io::IO, coeff::DCTCoeff)
    show(IOContext(io, :compact=>true), MIME("text/plain"), coeff)
end

function Base.show(io::IO, ::MIME"text/plain", coeff::DCCoeff)
    if get(io, :typeinfo, Any) === DCCoeff
        print(io, Int(coeff))
    else
        compact = get(io, :compact, false)
        name = compact ? "DCCoeff" : string(typeof(coeff))
        print(io, name, "(", Int(coeff), ")")
    end
end

function Base.show(io::IO, ::MIME"text/plain", coeff::ACCoeff)
    s = coeff.symbol
    compact = get(io, :compact, false)
    name = compact ? "ACCoeff" : string(typeof(coeff))
    if iseob(s)
        print(io, name, "(1, EOB)")
    elseif iseobn(s)
        print(io, name, "(", Int(coeff), ", EOB", runlength(s), ")")
    elseif length(coeff) == 1
        print(io, name, "(", Int(coeff), ")")
    elseif compact
        print(io, name, "(", Int(coeff), ", ", runlength(s), ")")
    else
        print(io, length(coeff), "-element ", typeof(coeff), ":")
        for c in coeff
            println(io)
            print(io, " ", c)
        end
    end
end
