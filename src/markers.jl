module Markers
# Start Of Frame markers, non-differential, Huffman coding
const SOF0 = 0xFFC0
const SOF1 = 0xFFC1
const SOF2 = 0xFFC2
const SOF3 = 0xFFC3

# Start Of Frame markers, differential, Huffman coding
const SOF5 = 0xFFC5
const SOF6 = 0xFFC6
const SOF7 = 0xFFC7

#Start Of Frame markers, non-differential, arithmetic coding
const JPG = 0xFFC8
const SOF9 = 0xFFC9
const SOF10 = 0xFFCA
const SOF11 = 0xFFCB

# Start Of Frame markers, differential, arithmetic coding
const SOF13 = 0xFFCD
const SOF14 = 0xFFCE
const SOF15 = 0xFFCF

# Huffman table specification
const DHT = 0xFFC4

# Arithmetic coding conditioning specification
const DAC = 0xFFCC

# Restart interval termination
const RST0 = 0xFFD0
const RST1 = 0xFFD1
const RST2 = 0xFFD2
const RST3 = 0xFFD3
const RST4 = 0xFFD4
const RST5 = 0xFFD5
const RST6 = 0xFFD6
const RST7 = 0xFFD7

# Other markers
const SOI = 0xFFD8
const EOI = 0xFFD9
const SOS = 0xFFDA
const DQT = 0xFFDB
const DNL = 0xFFDC
const DRI = 0xFFDD
const DHP = 0xFFDE
const EXP = 0xFFDF
const APP0 = 0xFFE0
const APP1 = 0xFFE1
const APP2 = 0xFFE2
const APP3 = 0xFFE3
const APP4 = 0xFFE4
const APP5 = 0xFFE5
const APP6 = 0xFFE6
const APP7 = 0xFFE7
const APP8 = 0xFFE8
const APP9 = 0xFFE9
const APP10 = 0xFFEA
const APP11 = 0xFFEB
const APP12 = 0xFFEC
const APP13 = 0xFFED
const APP14 = 0xFFEE
const APP15 = 0xFFEF
const JPG0 = 0xFFF0
const JPG1 = 0xFFF1
const JPG2 = 0xFFF2
const JPG3 = 0xFFF3
const JPG4 = 0xFFF4
const JPG5 = 0xFFF5
const JPG6 = 0xFFF6
const JPG7 = 0xFFF7
const JPG8 = 0xFFF8
const JPG9 = 0xFFF9
const JPG10 = 0xFFFA
const JPG11 = 0xFFFB
const JPG12 = 0xFFFC
const JPG13 = 0xFFFD
const COM = 0xFFFE

end # module Markers

const markers = Dict{UInt16,Symbol}(map(s -> (getfield(Markers, s), s),
                                        filter(s -> getfield(Markers, s) isa UInt16,
                                               names(Markers, all=true))))

struct Marker{symbol} end

function Marker(bits::UInt16)
    0xFF00 < bits < 0xFFFF || error("invalid marker: 0x", hex(bits))
    Marker{get(markers, bits, bits)}()
end

Base.sizeof(::Type{<:Marker}) = 2
Base.sizeof(::Marker) = 2

const SOI = Marker{:SOI}()
const EOI = Marker{:EOI}()

Base.show(io::IO, m::Marker) = print(io, typeof(m), "()")

Base.write(io::IO, m::Marker) = write(io, hton(reinterpret(UInt16, m)))

function Base.reinterpret(::Type{UInt16}, ::Marker{symbol}) where symbol
    symbol isa Symbol ? getfield(Markers, symbol) : symbol
end

==(x::Marker, y::Marker) = reinterpret(UInt16, x) === reinterpret(UInt16, y)
