
abstract type AbstractBlock{T<:Real} <: AbstractMatrix{T} end

const ZIGZAG = @SMatrix [
     1  2  6  7 15 16 28 29
     3  5  8 14 17 27 30 43
     4  9 13 18 26 31 42 44
    10 12 19 25 32 41 45 54
    11 20 24 33 40 46 53 55
    21 23 34 39 47 52 56 61
    22 35 38 48 51 57 60 62
    36 37 49 50 58 59 63 64
]

const ZIGZAG_INDICES = @SVector [findfirst(isequal(i), ZIGZAG) for i = 1:64]

Base.CartesianIndices(b::AbstractBlock) = ZIGZAG_INDICES

Base.getindex(b::AbstractBlock, y::Integer, x::Integer) = getindex(b, ZIGZAG[y, x])
Base.size(b::AbstractBlock) = (8, 8)
Base.length(b::AbstractBlock) = 64

abstract type Block{T<:Real} <: AbstractBlock{T} end

struct DCTBlock{T<:Real} <: Block{T}
    coeffs::SVector{64,T}
end

Base.getindex(b::DCTBlock, i::Integer) = b.coeffs[i]
