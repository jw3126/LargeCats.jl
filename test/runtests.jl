using LargeCats
const LC = LargeCats
using Test

@testset "internals" begin
    arr1 = randn(1,2,3)
    arr2 = randn(1,2,4)

    dims= (3,2)
    @test (1,4,7) === @inferred(LC.largecat_outsize([arr1, arr2], dims=(3,2)))
    @test Float64 === @inferred(LC.largecat_eltype([arr1, arr2]))

    @test (2,)    === @inferred(LC.largecat_outsize([[1,2]], dims=1))
    @test Int     === @inferred(LC.largecat_eltype([[1,2], [3,4]]))
    @test Int     === @inferred(LC.largecat_eltype(([1],[2])))
    @test Float64 === @inferred(LC.largecat_eltype(([1],[2.2])))

end

@testset "against cat" begin
    arr1 = randn(1,2,3)
    arr2 = randn(1,2,4)
    arrs = [arr1, arr2]
    dims = (2,3)
    @test @inferred(largecat(arrs, dims=dims)) == cat(arrs..., dims=dims)
end

@testset "largecat perf " begin
    function printrow(n, rel_time, tot_time, mem, outsize)
        println("|",
          rpad(string(n   ), 10), "|",
          rpad(string(rel_time), 15), "|",
          rpad(string(tot_time), 15), "|",
          rpad(string(mem), 15), "|",
          rpad(string(outsize), 15), "|",
        )
    end
    println("Performance counters")
    printrow("n arrays", "time/length/ns", "total time/s", "allocs/bytes", "outsize/bytes")

    for n in Int[1, 1e1, 1e2, 1e3, 1e4, 1e5, 1e6]
        arrs = map(1:Int(n)) do i
            rand(Float32, rand(1:3), 1)
        end
        largecat(arrs[1:1],dims=(1,)) # warmup
        stats = @timed largecat(arrs,dims=(1,))
        outsize = Base.summarysize(stats.value)
        rel_time = round(1e9*stats.time/length(stats.value), digits=3)
        printrow(n,rel_time , stats.time, stats.bytes, outsize)
        # @info "$(stats.time)s $(stats.bytes) bytes"
        @test outsize < stats.bytes < outsize + 1000
    end
end
