using Printf

# parameters:
# STREAM_ARRAY_SIZE = 100000000
# NTIMES            = 10
# OFFSET            = 0
# STREAM_TYPE       = double

const STREAM_ARRAY_SIZE = 100_000_000
const NTIMES = 10
# const OFFSET = 0
const scalar = 3.0
const label = ["Copy:\t", "Scale:\t", "Add:\t", "Triad:\t"]
const bytes = [
    2 * sizeof(Float64) * STREAM_ARRAY_SIZE,
    2 * sizeof(Float64) * STREAM_ARRAY_SIZE,
    3 * sizeof(Float64) * STREAM_ARRAY_SIZE,
    3 * sizeof(Float64) * STREAM_ARRAY_SIZE
]
const sep = "----------------------------------------------"

# only print 3 decimal places per default
Base.show(io::IO, f::Float64) = @printf(io, "%.3f", f)

function quantum()
    M = 20
    timesfound = Array{Float64, 1}(undef, M)
    for i in 1:M
	t1 = time_ns()
        while ((t2 = time_ns()) - t1) / 1e9 < 1e-6
	end
	timesfound[i] = (t1 = t2)
    end
    minDelta = 1000000
    for i in 2:M
	delta = floor(1e6 * (timesfound[i] - timesfound[i-1]))
	minDelta = min(minDelta, max(delta, 0))
    end
    return minDelta / 1e6
end

function checkResults(a::Array{Float64,1}, b::Array{Float64,1}, c::Array{Float64,1})
    aj::Float64 = 1.0
    bj::Float64 = 2.0
    cj::Float64 = 0.0

    # part of timing
    aj = 2.0 * aj

    for k in 1:NTIMES
        cj = aj
        bj = scalar * cj
        cj = aj + bj
        aj = bj + scalar * cj
    end

    aSumErr = 0.0
    bSumErr = 0.0
    cSumErr = 0.0
    for j in 1:STREAM_ARRAY_SIZE
        aSumErr += abs(a[j] - aj)
        bSumErr += abs(b[j] - bj)
        cSumErr += abs(c[j] - cj)
    end

    aAvgErr = aSumErr / STREAM_ARRAY_SIZE
    bAvgErr = bSumErr / STREAM_ARRAY_SIZE
    cAvgErr = cSumErr / STREAM_ARRAY_SIZE

    epsilon = 1.e-13

    err = 0
    if (abs(aAvgErr/aj) > epsilon)
        err += 1
        println("Validation of array a failed with rate: ", abs(aAvgErr/aj))
    end
    if (abs(bAvgErr/bj) > epsilon)
        err += 1
        println("Validation of array b failed with rate: ", abs(bAvgErr/bj))
    end
    if (abs(cAvgErr/cj) > epsilon)
        err += 1
        println("Validation of array c failed with rate: ", abs(cAvgErr/cj))
    end
    if (err == 0)
        println("Everything validated successfully with an error rate under: ", epsilon)
    end
end

# 1. setup data + arrays
# (2. give overview over expected time )
# 3. do benchmark
#   1. copy STREAM_ARRAY_SIZE values from array to array
#   2. do scalar multiplication on array
#   3. add STREAM_ARRAY_SIZE values from two arrays together and store in third
#   4. do triad: for all STREAM_ARRAY_SIZE values: a[j] = b[j] + scalar * c[j]
# 4. Calculate avg, min, max times
# 5. Print best bandwidth and times for each catagory

function main()
    # initialization
    a = Array{Float64, 1}(undef, STREAM_ARRAY_SIZE)
    b = Array{Float64, 1}(undef, STREAM_ARRAY_SIZE)
    c = Array{Float64, 1}(undef, STREAM_ARRAY_SIZE)

    arraySize = sizeof(Float64) * STREAM_ARRAY_SIZE / 1024 / 1024

    println("STREAM.jl")
    println(sep)
    println("This run uses ", STREAM_ARRAY_SIZE, " values of size ", sizeof(Float64))
    println("Memory per array = ", arraySize, " MiB (= ", arraySize / 1024, " GiB)")
    println("Total memory = ", arraySize * 3, " MiB")
    println(sep)

    Threads.@threads for i in 1:STREAM_ARRAY_SIZE
        a[i] = 1.0
        b[i] = 2.0
        c[i] = 0.0
    end

    times = zeros(Float64, 4, NTIMES)

    avgtime = zeros(4)
    maxtime = zeros(4)
    mintime = fill(typemax(Float64), 4)

    println("Using ", Threads.nthreads(), " threads")

    # part of the timer code
    tmp = time_ns()
    Threads.@threads for i in 1:STREAM_ARRAY_SIZE
        a[i] = 2.0 * a[i]
    end
    tmp = (time_ns() - tmp) * 1e-3

    println("Each test below will take on the order of ", tmp, " microseconds")
    println("That equals ", tmp / quantum(), " clock ticks")
    println(sep)

    for k in 1:NTIMES
	times[1,k] = time_ns()
        Threads.@threads for j in 1:STREAM_ARRAY_SIZE
            c[j] = a[j]
        end
        times[1,k] = time_ns() - times[1,k]

	times[2,k] = time_ns()
        Threads.@threads for j in 1:STREAM_ARRAY_SIZE
            b[j] = scalar * c[j]
        end
        times[2,k] = time_ns() - times[2,k]

	times[3,k] = time_ns()        
	Threads.@threads for j in 1:STREAM_ARRAY_SIZE
            c[j] = a[j] + b[j]
        end
        times[3,k] = time_ns() - times[3,k]

        times[4,k] = time_ns()
	Threads.@threads for j in 1:STREAM_ARRAY_SIZE
            a[j] = b[j] + scalar * c[j]
        end
        times[4,k] = time_ns() - times[4,k]
        

	#tmp = @timed Threads.@threads for j in 1:STREAM_ARRAY_SIZE
        #    c[j] = a[j]
        #end
        #times[1,k] = tmp[2]

        #tmp = @timed Threads.@threads for j in 1:STREAM_ARRAY_SIZE
        #    b[j] = scalar * c[j]
        #end
        #times[2,k] = tmp[2]

        #tmp = @timed Threads.@threads for j in 1:STREAM_ARRAY_SIZE
        #    c[j] = a[j] + b[j]
        #end
        #times[3,k] = tmp[2]

        #tmp = @timed Threads.@threads for j in 1:STREAM_ARRAY_SIZE
        #    a[j] = b[j] + scalar * c[j]
        #end
        #times[4,k] = tmp[2]
    end

    # the first is only for warmup
    for k in 2:NTIMES
        for j in 1:4
	    times[j,k] = times[j,k] * 1e-9
            avgtime[j] = avgtime[j] + times[j,k]
            mintime[j] = min(mintime[j], times[j,k])
            maxtime[j] = max(maxtime[j], times[j,k])
        end
    end

    println("Function   Best Rate MB/s  Avg time    Min time    Max time")
    for j in 1:4
        avgtime[j] = avgtime[j]/(NTIMES - 1)
        Printf.@printf "%s%12.1f  %11.6f  %11.6f  %11.6f\n" label[j] 1.0e-6 * bytes[j]/mintime[j] avgtime[j] mintime[j] maxtime[j]
    end
    checkResults(a, b, c)
end


main()
