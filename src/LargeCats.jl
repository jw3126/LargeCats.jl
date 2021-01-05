module LargeCats
export largecat

function similar_ntuple(f, t::NTuple{N, <: Any}) where {N}
    ntuple(f, N)
end

function ifelse_dims(f_in_dims, f_else, t1::Tuple, t2::Tuple, dims)
    map(similar_ntuple(identity, t1), t1, t2) do i, x1, x2
        if i in dims
            f_in_dims(x1,x2)
        else
            f_else(x1,x2)
        end::Int
    end
end

function ifelse_dims(f_in_dims, f_else, c1::CartesianIndex, c2::CartesianIndex, dims)
    t = ifelse_dims(f_in_dims, f_else, Tuple(c1), Tuple(c2), dims)
    CartesianIndex(t)
end

firstarg(x1,x2) = x1
secondarg(x1,x2) = x2
samearg(x1, x2) = (@assert x1 === x2; x1)
@noinline function largecat!(out::AbstractArray{N}, itr; dims) where {N}
    Base.require_one_based_indexing(out)
    I_start = first(CartesianIndices(out))
    I_outsize = CartesianIndex(size(out))
    I_stop  = ifelse_dims((i1, i2) -> i1-1, secondarg, I_start, I_outsize, dims)
    for x in itr
        Base.require_one_based_indexing(x)
        I_size = CartesianIndex(size(x))
        I_stop = ifelse_dims(+, firstarg, I_stop, I_size, dims)
        # @show I_size
        # @show I_start
        # @show I_stop
        out[I_start:I_stop] .= x
        I_start = ifelse_dims(+, firstarg, I_start, I_size, dims)
    end
    out
end

function largecat(itr; dims)
    T = largecat_eltype(itr)
    outsize = largecat_outsize(itr, dims=dims)
    out = zeros(T, outsize)
    largecat!(out, itr, dims=dims)
end

function largecat_outsize(itr; dims)
    dims1 = size(first(itr))
    out_size = map(similar_ntuple(identity, dims1), dims1) do i, d
        if i in dims
            0
        else
            d
        end
    end
    for x in itr
        Base.require_one_based_indexing(x)
        out_size = ifelse_dims(+, samearg, out_size, size(x), dims)
    end
    return out_size
end

function largecat_eltype(itr)
    T = eltype(eltype(itr))
    if Base.isconcretetype(T)
        return T
    else
        compute_largecat_eltype(itr)
    end
end

function compute_largecat_eltype(itr)
    mapreduce(eltype, promote_type, itr)
end

end #module
