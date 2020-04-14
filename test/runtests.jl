using Test, LowLevelJPEG

using StaticArrays

ambiguities_lljpeg = detect_ambiguities(LowLevelJPEG, Base, Core)
ambiguities_sarray = detect_ambiguities(StaticArrays, Base, Core)

@test isempty(setdiff(ambiguities_lljpeg, ambiguities_sarray))

const dir = joinpath(dirname(pathof(LowLevelJPEG)), "..", "test", "res")

function readtest(filename::AbstractString, t::Type, offset::Integer)
    open(joinpath(dir, filename), "r") do f
        seek(f, offset)
        return read(f, t)
    end
end
readtest(t::Type, offset::Integer) = readtest("julia.jpg", t, offset)

function shown_string(obj)
    io = IOBuffer()
    show(io, obj)
    String(take!(io))
end

function shown_plaintext(obj)
    io = IOBuffer()
    show(io, MIME("text/plain"), obj)
    seekstart(io)
    join(map(rstrip, eachline(io)), "\n") # remove trailing whitespace
end

function written_hex(obj)
    io = IOBuffer()
    write(io, obj)
    bytes2hex(take!(io))
end

@testset "Markers" begin
    include("markers.jl")
end
