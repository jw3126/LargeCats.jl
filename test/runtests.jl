using LargeCats
const LC = LargeCats
using Test

@testset "internals" begin
    arr1 = randn(1, 2, 3)
    arr2 = randn(1, 2, 4)

    dims = (3, 2)
    @test (1, 4, 7) === @inferred(LC.largecat_outsize([arr1, arr2], dims = (3, 2)))
    @test Float64 === @inferred(LC.largecat_eltype([arr1, arr2]))

    @test (2,) === @inferred(LC.largecat_outsize([[1, 2]], dims = 1))
    @test Int === @inferred(LC.largecat_eltype([[1, 2], [3, 4]]))
    @test Int === @inferred(LC.largecat_eltype(([1], [2])))
    @test Float64 === @inferred(LC.largecat_eltype(([1], [2.2])))

end

@testset "against cat" begin
    arr1 = randn(1, 2, 3)
    arr2 = randn(1, 2, 4)
    arrs = [arr1, arr2]
    dims = (2, 3)
    @test @inferred(largecat(arrs, dims = dims)) == cat(arrs..., dims = dims)

    function rand_setup()
        T = rand([Int8, Int, Float32, Float64])
        ndims = rand(1:5)
        dim = rand(1:ndims)
        base_shape = rand(1:10, ndims)
        nshapes = rand(1:50)
        shapes = NTuple{ndims, Int}[]
        for _ in 1:nshapes
            shape = copy(base_shape)
            shape[dim] = rand(1:10)
            push!(shapes, Tuple(shape))
        end
        return (T=T, shapes=shapes, dims=dim)
    end

    for _ in 1:100
        setup = rand_setup()
        arrs = [rand(setup.T, shape) for shape in setup.shapes]
        @test @inferred(largecat(arrs, dims=setup.dims)) == cat(arrs..., dims=setup.dims)
    end
end

if VERSION >= v"1.5"
    @testset "largecat perf " begin
        function printrow(n, rel_time, tot_time, mem, outsize)
            println(
                "|",
                rpad(string(n), 10),
                "|",
                rpad(string(rel_time), 15),
                "|",
                rpad(string(tot_time), 15),
                "|",
                rpad(string(mem), 15),
                "|",
                rpad(string(outsize), 15),
                "|",
            )
        end
        println("Performance counters")
        printrow(
            "n arrays",
            "time/length/ns",
            "total time/s",
            "allocs/bytes",
            "outsize/bytes",
        )

        for n in Int[1, 1e1, 1e2, 1e3, 1e4, 1e5, 1e6]
            arrs = map(1:Int(n)) do i
                rand(Float32, rand(1:3), 1)
            end
            largecat(arrs[1:1], dims = (1,)) # warmup
            stats = @timed largecat(arrs, dims = (1,))
            outsize = Base.summarysize(stats.value)
            rel_time = round(1e9 * stats.time / length(stats.value), digits = 3)
            printrow(n, rel_time, stats.time, stats.bytes, outsize)
            # @info "$(stats.time)s $(stats.bytes) bytes"
            @test outsize < stats.bytes < outsize + 1000
        end

        println("Special situations")
        printrow("setup", "time/length/ns", "total time/s", "allocs/bytes", "outsize/bytes")
        for setup in [
            (
                T = Float32,
                shapes = [
                    (128, 128, 1, 1),
                    (128, 128, 2, 1),
                    (128, 128, 3, 1),
                    (128, 128, 4, 1),
                ],
                dims = 3,
            ),
            (
                T = Float32,
                shapes = [(128, 128, 128, 1, 1), (128, 128, 128, 1, 1)],
                dims = 4,
            ),
        ]
            arrs = map(shape -> randn(setup.T, shape), setup.shapes)
            out = largecat(arrs, dims = setup.dims)
            stats = @timed largecat(arrs, dims = setup.dims)
            outsize = Base.summarysize(stats.value)
            rel_time = round(1e9 * stats.time / length(stats.value), digits = 3)
            printrow(
                "$(length(arrs))x$(ndims(out))d",
                rel_time,
                stats.time,
                stats.bytes,
                outsize,
            )
            @test outsize < stats.bytes < outsize + 1000
        end
    end
end
