
struct QuantizationTable{T <: Union{UInt8, UInt16}} <: AbstractBlock{T}
    id::UInt8
    table::SVector{64,T}
    function QuantizationTable{T}(table::AbstractArray; id::Integer=0) where T
        id < 4 || error("`id` must be less than 4.")
        if size(table) == (8, 8)
            new{T}(id, [table[i] for i in ZIGZAG_INDICES])
        else
            new{T}(id, table)
        end
    end
end
QuantizationTable{T}(table::QuantizationTable{T}; id::Integer=table.id) where T =
    QuantizationTable{T}(table.table, id=id)

const QuantizationTable8 = QuantizationTable{UInt8}
const QuantizationTable16 = QuantizationTable{UInt16}

qt_precision(::QuantizationTable{T}) where T = 8sizeof(T)

Base.sizeof(::Type{QuantizationTable{T}}) where T = 1 + 64sizeof(T)
Base.sizeof(qt::QuantizationTable) = sizeof(typeof(qt))

Base.getindex(qt::QuantizationTable, i::Integer) = qt.table[i]


function Base.show(io::IO, qt::QuantizationTable{T}) where T
    id = Int(qt.id)
    bits = qt_precision(qt)
    print(io, "QuantizationTable", bits, "([")
    for y = 1:7
        print(io, join(string.(qt[y,:]), " "), "; ")
    end
    print(io, join(string.(qt[8,:]), " "), "], id=", qt.id, ")")
end

function Base.show(io::IO, ::MIME"text/plain", qt::QuantizationTable{T}) where T
    id = Int(qt.id)
    bits = qt_precision(qt)
    print(io, "8×8 ", bits, "-bit QuantizationTable{", T, "}(id=", id, "):")
    len = ndigits(maximum(qt)) + 2
    for y = 1:8
        println(io)
        for x = 1:8
            print(io, lpad(string(qt[y,x]), len))
        end
    end
end

function Base.read(io::IO, t::Type{<:QuantizationTable})
    pq, tq = u4u4(io)
    isconcretetype(t) && sizeof(eltype(t)) != pq - 1 && error("precision mismatch")
    if pq == 0x0
        return QuantizationTable8(read(io, 64), id=tq)
    elseif pq == 0x1
        return QuantizationTable16(hton.(read(io, UInt16, 64)), id=tq)
    else
        error()
    end
end

function Base.write(io::IO, qt::QuantizationTable)
    p = qt_precision(qt) == 8 ? 0x00 : 0x10
    write(io, qt.id | p)
    write(io, hton.(qt.table))
end


quantize(s::S, q::T) where {S, T} = q == zero(T) ? zero(S) : convert(S, round(s / q))
dequantize(s::S, q::T) where {S, T} = convert(S, s * q)

quantize(b::DCTBlock, qt::QuantizationTable) = DCTBlock(quantize.(b, qt))
dequantize(b::DCTBlock, qt::QuantizationTable) = DCTBlock(dequantize.(b, qt))
