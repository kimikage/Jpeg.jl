
abstract type HuffmanTreeNode{T<:SourceSymbol} end

# construct from tuples
HuffmanTreeNode(   t::Tuple{T, <:Real}) where T<:SourceSymbol = HuffmanSymbolNode{T}(t...)
HuffmanTreeNode{T}(t::Tuple{T, <:Real}) where T<:SourceSymbol = HuffmanSymbolNode{T}(t...)
HuffmanTreeNode{T}(t::Tuple{UInt8, <:Real}) where T<:SourceSymbol = HuffmanSymbolNode{T}(t...)
HuffmanTreeNode(t::Tuple{<:HuffmanTreeNode{T}, <:HuffmanTreeNode{T}}) where T<:SourceSymbol =
    HuffmanBranchNode{T}(t...)
HuffmanTreeNode{T}(t::Tuple{<:HuffmanTreeNode{T}, <:HuffmanTreeNode{T}}) where T<:SourceSymbol =
    HuffmanBranchNode{T}(t...)
HuffmanTreeNode{T}(t::Tuple{Tuple, Tuple}) where T<:SourceSymbol =
    HuffmanBranchNode{T}(HuffmanTreeNode{T}(t[1]), HuffmanTreeNode{T}(t[2]))

Base.convert(::Type{T}, t::Tuple) where T <: HuffmanTreeNode = T(t)

Base.show(io::IO, t::HuffmanTreeNode) = print_tree(io, t)
AbstractTrees.nodetype(::HuffmanTreeNode{T}) where T = HuffmanTreeNode{T}


struct HuffmanSymbolNode{T<:SourceSymbol} <: HuffmanTreeNode{T}
    symbol::T
    probability::Float64
    HuffmanSymbolNode{T}(symbol::T, p::Float64=0.0) where T = new(symbol, p)
    HuffmanSymbolNode{T}(symbol::UInt8, p::Float64=0.0) where T = new(symbol, p)
end

const DCSymbolNode = HuffmanSymbolNode{DCSymbol}
const ACSymbolNode = HuffmanSymbolNode{ACSymbol}

HuffmanSymbolNode(symbol::T, p::Float64=0.0) where T = HuffmanSymbolNode{T}(symbol, p)

AbstractTrees.children(s::HuffmanSymbolNode) = ()
AbstractTrees.printnode(io::IO, s::HuffmanSymbolNode) = print(io, s)

function Base.show(io::IO, s::HuffmanSymbolNode{T}) where T <: Union{DCSymbol, ACSymbol}
    compact = get(io, :compact, false)
    if compact
        print(io, T === DCSymbol ? "DCSymbolNode" : "ACSymbolNode")
    else
        print(io, typeof(s))
    end
    print(IOContext(io, :typeinfo=>T), "(", s.symbol, ", ", s.probability, ")")
end

struct HuffmanBranchNode{T<:SourceSymbol} <: HuffmanTreeNode{T}
    n0::HuffmanTreeNode{T} # bit 0
    n1::HuffmanTreeNode{T} # bit 1
    probability::Float64
    HuffmanBranchNode{T}(n0::HuffmanTreeNode{T}, n1::HuffmanTreeNode{T}) where T<:SourceSymbol =
        new(n0, n1, n0.probability + n1.probability)
end
HuffmanBranchNode(n0::HuffmanTreeNode{T}, n1::HuffmanTreeNode{T}) where T<:SourceSymbol =
    HuffmanBranchNode{T}(n0, n1)

AbstractTrees.children(b::HuffmanBranchNode) = (b.n0, b.n1)
AbstractTrees.printnode(io::IO, b::HuffmanBranchNode) = print(io, "・")

struct HuffmanTree{T<:SourceSymbol}
    root::HuffmanTreeNode{T}
end

const DCHuffmanTree = HuffmanTree{DCSymbol}
const ACHuffmanTree = HuffmanTree{ACSymbol}

# The following method creates a huffman tree based on the probabilities.
# Note that the code assignment is not unique and the result is not normalized.
function HuffmanTree(nodes::AbstractVector{S}) where {T, S<:HuffmanTreeNode{T}}
    length(nodes) < 1 && error()
    t = collect(HuffmanTreeNode{T}, nodes)
    while length(t) > 1
        sort!(t, alg=InsertionSort, by=n->n.probability, rev=true)
        # pop the two nodes with the lowest probability
        n1 = pop!(t)
        n0 = pop!(t)
        # push a new branch node with the two nodes as children
        push!(t, HuffmanBranchNode(n0, n1))
    end
    HuffmanTree(t[1])
end

AbstractTrees.children(t::HuffmanTree) = children(t.root)
AbstractTrees.printnode(io::IO, t::HuffmanTree) = print(io, typeof(t))
AbstractTrees.nodetype(::HuffmanTree{T}) where T = HuffmanTreeNode{T}

function Base.show(io::IO, t::HuffmanTree{T}) where T
    function p(io::IO, s::HuffmanSymbolNode{T})
        print(io, "(", s.symbol, ", ", s.probability, ")")
    end
    function p(io::IO, b::HuffmanBranchNode{T})
        print(io, "(")
        p(io, b.n0)
        print(io, ", ")
        p(io, b.n1)
        print(io, ")")
    end
    print(io, typeof(t), "(")
    p(IOContext(io, :compact=>true, :typeinfo=>T), t.root)
    print(io, ")")
end

function Base.show(io::IO, ::MIME"text/plain", t::HuffmanTree{T}) where T
    table = HuffmanTable(t)
    n = 0
    maxdepth = 0
    for li in table.len
        n += li
        n > 20 && break
        maxdepth += 1
    end
    print_tree(IOContext(io, :compact=>true, :typeinfo=>T), t, maxdepth)
end

height(t::HuffmanSymbolNode) = 0
height(t::HuffmanBranchNode) = 1 + max(height(t.n0), height(t.n1))
height(t::HuffmanTree) = height(t.root)


struct HuffmanTable{T<:SourceSymbol}
    id::UInt8 # Th: Huffman table destination identifier
    len::SVector{16, UInt8} # Li
    symbols::AbstractVector{T} # Vij

    function HuffmanTable{T}(len::AbstractVector{<:Integer},
                             symbols::AbstractVector{T};
                             id::Integer=0) where T <: SourceSymbol
        id < 4 || error("`id` must be less than 4.")
        new{T}(id, len, symbols)
    end
end

const DCHuffmanTable = HuffmanTable{DCSymbol}
const ACHuffmanTable = HuffmanTable{ACSymbol}

Base.sizeof(ht::HuffmanTable) = length(ht) + 17
Base.length(ht::HuffmanTable) = length(ht.symbols)

# HuffmanTree <--> HuffmanTable conversions
function HuffmanTree(table::HuffmanTable{T}) where T <: SourceSymbol
    length(table) < 1 && error()
    symbols = collect(zip(table.symbols, codelist(table)))
    # set probability based on the code length
    node(sc) = HuffmanSymbolNode(sc[1], 0.5^length(sc[2]))
    function split(s, depth)
        length(s) == 1 && return node(s[1])
        s0 = filter(sc -> !sc[2][depth], s) # the `depth`-th bit is zero
        s1 = filter(sc ->  sc[2][depth], s) # the `depth`-th bit is one
        n0 = length(s0) == 1 ? node(s0[1]) : split(s0, depth + 1)
        n1 = length(s1) == 1 ? node(s1[1]) : split(s1, depth + 1)
        HuffmanBranchNode(n0, n1)
    end
    HuffmanTree(split(symbols, 1))
end

function HuffmanTable(tree::HuffmanTree{T}, id::Integer=0) where T <: SourceSymbol
    symbols = Tuple{T, Int}[]
    en(t::HuffmanSymbolNode, d::Int) = push!(symbols, (t.symbol, d))
    en(t::HuffmanBranchNode, d::Int) = (en(t.n0, d + 1); en(t.n1, d + 1))
    en(tree.root, 0)
    sort!(symbols, by=(s->s[2]))
    len = UInt8[count(s->s[2]==i, symbols) for i = 1:16]
    HuffmanTable{T}(len, (s->s[1]).(symbols), id=id)
end

function Base.read(io::IO, t::Type{<:HuffmanTable})
    tc, th = u4u4(io)
    len = Vector{UInt8}(undef, 16)
    readbytes!(io, len, 16)
    slen = sum(len)
    symbols = Vector{UInt8}(undef, slen)
    readbytes!(io, symbols, slen)
    t === DCHuffmanTable && tc != 0x0 && error("AC/DC type mismatch")
    t === ACHuffmanTable && tc != 0x1 && error("AC/DC type mismatch")
    if tc == 0x0
        return DCHuffmanTable(len, DCSymbol.(symbols), id=th)
    elseif tc == 0x1
        return ACHuffmanTable(len, ACSymbol.(symbols), id=th)
    else
        error()
    end
end

function codetable(ht::HuffmanTable)
    code = code""
    function u()
        prev = code
        code = inc(code)
        prev
    end
    function v(n)
        code = shl(code)
        CodeBits[u() for j = 1:n]
    end
    SVector{16, Vector{CodeBits}}([v(Int(ht.len[i])) for i = 1:16])
end

codelist(ht::HuffmanTable) = reduce(vcat, codetable(ht), init=[])

function Base.show(io::IO, ht::HuffmanTable)
    print(io, typeof(ht), "([", join(string.(Int.(ht.len)), ", "), "], ")
    print(io, ht.symbols, ", id=", ht.id, ")")
end

function Base.show(io::IO, ::MIME"text/plain", ht::HuffmanTable)
    print(io, length(ht), "-symbol ", typeof(ht), "(id=", ht.id, "):")
    codes = codelist(ht)
    for (s, c) in zip(ht.symbols, codes)
        println(io)
        print(io, " ", s, "  ", c)
    end
end

struct HuffmanDecoder{T<:SourceSymbol}
    symbols::AbstractVector{T}
    codes::AbstractVector{CodeBits}
    index8::SVector{256, Int32} # for codes with length not greater than 8 bits
    indexx::Integer # first index which is out of index8

    function HuffmanDecoder{T}(table::HuffmanTable{T}) where {T<:SourceSymbol}
        symbols = table.symbols
        codes = codelist(table)
        index8 = zeros(Int32, 256)

        length(codes) > 256 && error()
        # e.g.
        # table.len = [0, 1, 5, ..., 0]
        # bitlen=1 -> none
        # bitlen=2 -> code"00"
        # bitlen=3 -> code"010", code"011", code"100", code"101", code"110"
        #
        # 0b00_000000 : 0b00_111111 -> index=1 (w=64, 6 bits)
        #   __ ^^^^^^     __ ^^^^^^
        # 0b010_00000 : 0b010_11111 -> index=2 (w=32, 5 bits)
        # 0b011_00000 : 0b011_11111 -> index=3 (w=32, 5 bits)
        # 0b100_00000 : 0b100_11111 -> index=4 (w=32, 5 bits)
        # 0b101_00000 : 0b101_11111 -> index=5 (w=32, 5 bits)
        # 0b110_00000 : 0b110_11111 -> index=6 (w=32, 5 bits)
        #   ___ ^^^^^     ___ ^^^^^
        index = 1
        p = 0
        for bitlen = 1:8
            w = 0x100 >> bitlen
            for k = 1:table.len[bitlen]
                index8[p+1:p+w] .= index
                index += 1
                p += w
            end
        end
        new{T}(symbols, codes, index8, index)
    end
end

struct BitSequenceError <: Exception end

HuffmanDecoder(table::HuffmanTable{T}) where {T<:SourceSymbol} = HuffmanDecoder{T}(table)

function getcodeindex(d::HuffmanDecoder, bits::UInt32, effective_length::Integer)
    index = d.index8[(bits >> 24) + 1]
    if index > 0 # matched
        c = d.codes[index]
        return effective_length < length(c) ? 0 : index
    end
    for i = d.indexx:length(d.codes)
        c = d.codes[i]
        l = length(c)
        if effective_length < l
            delta = UInt8(l - effective_length)
            (word(c) >> delta) >= (bits >> UInt8(32 - effective_length)) && return 0
            throw(BitSequenceError())
        end
        c == CodeBits(l, bits >> UInt8(32 - l)) && return i
    end
    throw(BitSequenceError())
end
