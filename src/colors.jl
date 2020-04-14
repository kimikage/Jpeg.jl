const JPEGColorEltype = Union{UInt8, UInt16, Float16, Float32, Float64}

"""
    JPEGGray{T}

See also [`JPEGYCbCr`](@ref)
"""
struct JPEGGray{T <: JPEGColorEltype} <: Color{T, 1}
    val::T
    JPEGGray{T}(x::T) where T = new{T}(x)
end
JPEGGray(x::T) where T <: JPEGColorEltype = JPEGGray{T}(x)

JPEGGray{UInt8}(x::AbstractGray) =
    JPEGGray{UInt8}(unsafe_trunc(UInt8, round(float(gray(x)) * 255)))
JPEGGray{UInt16}(x::AbstractGray) =
    JPEGGray{UInt16}(unsafe_trunc(UInt16, round(float(gray(x)) * 32640)))
JPEGGray{T}(x::AbstractGray) where T =
    JPEGGray{T}(convert(T, float(gray(x)) * T(255)))
JPEGGray(x::AbstractGray{T}) where T <: JPEGColorEltype = JPEGGray{T}(x)



const JPEGGray8  = JPEGGray{UInt8}
const JPEGGray16 = JPEGGray{UInt16}

ColorTypes.gray(g::JPEGGray{T}) where T <: AbstractFloat = g.val / T(255)
ColorTypes.gray(g::JPEGGray8) = reinterpret(N0f8, g.val)
ColorTypes.gray(g::JPEGGray16) = reinterpret(N0f16, g.val + g.val + (g.val >> 0x7))

ColorTypes.comp1(g::JPEGGray8) = Float32(Int16(g.val))
ColorTypes.comp1(g::JPEGGray16) = Float32(signed(g.val)) * Float32(0x1p-7)

"""
    JPEGYCbCr{T}

The YCbCr color of JFIF. This is based on a modified ITU-R BT.601 (formerly CCIR
 601).

# Internal ranges
- `JPEGYCbCr8`
  - `Y`: [0, 255]
  - `Cb`, `Cr`: [-128, 127]
    - *Note1:* a value in (127, 127.5] is clamped to 127.
    - *Note2:* the binary representation of `Cb`/`Cr` is a `UInt8` number with
      a bias ``+128`.
- `JPEGYCbCr16`
  - `Y`: [-256, 255.992]
  - `Cb`, `Cr`: [-256, 255.992]
"""
struct JPEGYCbCr{T <: JPEGColorEltype} <: Color{T, 3}
    y::T
    cb::T
    cr::T
end

const JPEGYCbCr8  = JPEGYCbCr{UInt8}
const JPEGYCbCr16 = JPEGYCbCr{UInt16}

ColorTypes.gray(ycc::JPEGYCbCr{T}) where T <: AbstractFloat = ycc.y / T(255)
ColorTypes.gray(ycc::JPEGYCbCr8)  = reinterpret(N0f8, ycc.y)
ColorTypes.gray(ycc::JPEGYCbCr16) = reinterpret(N0f16, ycc.y + ycc.y + (ycc.y >> 0x7))

ColorTypes.comp1(ycc::JPEGYCbCr8) = Float32(Int16(ycc.y))
ColorTypes.comp1(ycc::JPEGYCbCr16) = Float32(signed(ycc.y)) * Float32(0x1p-7)
ColorTypes.comp2(ycc::JPEGYCbCr8)  = Float32(signed(ycc.cb - 0x80))
ColorTypes.comp2(ycc::JPEGYCbCr16) = Float32(signed(ycc.cb)) * Float32(0x1p-7)
ColorTypes.comp3(ycc::JPEGYCbCr8)  = Float32(signed(ycc.cr - 0x80))
ColorTypes.comp3(ycc::JPEGYCbCr16) = Float32(signed(ycc.cr)) * Float32(0x1p-7)

clamp01(x::T) where T = min(max(x, zero(T)), oneunit(T))

clampy(::Type{UInt8}, x::T) where T =
    unsafe_trunc(UInt8, round(min(max(x, T(0)), T(255))))
clampc(::Type{UInt8}, x::T) where T = clampy(UInt8, x + T(128))

clampy(::Type{UInt16}, x::T) where T =
    unsafe_trunc(UInt16, round(min(max(x * T(0x1p7), T(-32768)), T(32767))))
clampc(::Type{UInt16}, x::T) where T = clampy(UInt16, x)

clampy(::Type{U}, x) where U <: AbstractFloat = convert(U, x)
clampc(::Type{U}, x) where U <: AbstractFloat = convert(U, x)


function ColorTypes._convert(::Type{Cout}, ::Type{C1}, ::Type{C2},
                             c) where {T,Cout<:JPEGGray{T},C1<:JPEGGray,C2<:Color}
    convert(Cout, convert(RGB, c))
end
function ColorTypes._convert(::Type{Cout}, ::Type{C1}, ::Type{C2},
                             c) where {T,Cout<:JPEGGray{T},C1<:JPEGGray,C2<:AbstractGray}
    if T === UInt8 && eltype(c) === N0f8
        Cout(reinterpret(gray(c)))
    elseif T === UInt16 && eltype(c) <: Union{N0f8, N8f8}
        Cout(T(reinterpret(gray(c))) << 0x7)
    else
        Cout(c)
    end
end
function ColorTypes._convert(::Type{Cout}, ::Type{C1}, ::Type{C2},
                             c) where {T,Cout<:JPEGGray{T},C1<:JPEGGray,C2<:AbstractRGB}
    rgb_to_gray(Cout, red(c), green(c), blue(c))
end

function rgb_to_gray(::Type{JPEGGray{U}}, r::T, g::T, b::T) where {U, T}
    F = floattype(T)
    y = F(0.299) * r + F(0.587) * g + F(0.114) * b
    JPEGGray{U}(Gray(y))
end

function ColorTypes._convert(::Type{Cout}, ::Type{C1}, ::Type{C2},
                             c) where {T,Cout<:JPEGYCbCr{T},C1,C2}
    convert(Cout, convert(RGB, c))
end
function ColorTypes._convert(::Type{Cout}, ::Type{C1}, ::Type{C2},
                             c) where {T,Cout<:JPEGYCbCr{T},C1<:JPEGYCbCr,C2<:AbstractRGB}
    rgb_to_ycbcr(Cout, red(c), green(c), blue(c))
end
function ColorTypes._convert(::Type{Cout}, ::Type{C1}, ::Type{C2},
                             c) where {T,Cout<:JPEGYCbCr{T},C1<:JPEGYCbCr,C2<:JPEGYCbCr}
    Cout(clampy(T, comp1(c)), clampc(T, comp2(c)), clampc(T, comp3(c)))
end
function rgb_to_ycbcr(t, r::T, g::T, b::T) where T <: Union{N0f8, N8f8}
    rgb255_to_ycbcr(t,
                    Float32(reinterpret(r)),
                    Float32(reinterpret(g)),
                    Float32(reinterpret(b)))
end
function rgb_to_ycbcr(t, r::T, g::T, b::T) where T
    rgb255_to_ycbcr(t, float(r) * 255, float(g) * 255, float(b) * 255)
end

# the coefficients come from the libjpeg implementation, instead of the original
# JFIF specification v1.02.
function rgb255_to_ycbcr(::Type{JPEGYCbCr{U}}, r::T, g::T, b::T) where {U, T}
    JPEGYCbCr{U}(
        clampy(U, T( 0.299000000) * r + T(0.587000000) * g + T(0.114000000) * b),
        clampc(U, T(-0.168735892) * r - T(0.331264108) * g + T(0.500000000) * b),
        clampc(U, T( 0.500000000) * r - T(0.418687589) * g - T(0.081312411) * b)
    )
end

function ColorTypes._convert(::Type{Cout}, ::Type{C1}, ::Type{C2},
                             c) where {Cout<:Color3, C1, C2<:JPEGYCbCr}
    convert(Cout, ycbcr_to_rgb(RGB{eltype(Cout)}, c))
end
function ColorTypes._convert(::Type{Cout}, ::Type{C1}, ::Type{C2},
                             c) where {Cout<:AbstractRGB,C1<:AbstractRGB,C2<:JPEGYCbCr}
    ycbcr_to_rgb(Cout, c)
end

# The conversion between sRGB and YCbCr defined in Color.jl is not compatible
# with the JFIF specification.
function ycbcr_to_rgb(::Type{C}, ycc::JPEGYCbCr) where {T, C <: AbstractRGB{T}}
    y, cb, cr = comp1(ycc), comp2(ycc), comp3(ycc)
    F = typeof(y)
    r = muladd(F(1.402), cr, y)
    g = y - muladd(F(0.344136286), cb, F(0.714136286) * cr)
    b = muladd(F(1.772), cb, y)
    if T === N0f8
        C(reinterpret(T, clampy(UInt8, r)),
          reinterpret(T, clampy(UInt8, g)),
          reinterpret(T, clampy(UInt8, b)))
    else
        C(clamp01(r / 255), clamp01(g / 255), clamp01(b / 255))
    end
end

function Base.show(io::IO, c::C) where {T <: Union{UInt8, UInt16}, C <: JPEGGray{T}}
    print(io, nameof(C), 8sizeof(T), "(")
    if T === UInt8
        print(io, string(Int(c.val)), ")")
    else
        print(io, string(round(Float64(comp1(c)), digits=3)), ")")
    end
end
function Base.show(io::IO, c::C) where {T <: Union{UInt8, UInt16}, C <: JPEGYCbCr{T}}
    print(io, nameof(C), 8sizeof(T), "(")
    if T === UInt8
        print(io, string(Int(c.y)), ",")
        print(io, string(signed(c.cb - 0x80)), ",")
        print(io, string(signed(c.cr - 0x80)), ")")
    else
        print(io, string(round(Float64(comp1(c)), digits=3)), ",")
        print(io, string(round(Float64(comp2(c)), digits=3)), ",")
        print(io, string(round(Float64(comp3(c)), digits=3)), ")")
    end
end
