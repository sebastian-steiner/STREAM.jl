# parameters:
# STREAM_ARRAY_SIZE = 10000000
# NTIMES            = 10
# OFFSET            = 0
# STREAM_TYPE       = double

# 1. setup data + arrays
# (2. give overview over expected time )
# 3. do benchmark
#   1. copy STREAM_ARRAY_SIZE values from array to array
#   2. do scalar multiplication on array
#   3. add STREAM_ARRAY_SIZE values from two arrays together and store in third
#   4. do triad: for all STREAM_ARRAY_SIZE values: a[j] = b[j] + scalar * c[j]
# 4. Calculate avg, min, max times
# 5. Print best bandwidth and times for each catagory