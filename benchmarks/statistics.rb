require 'daru'
require 'benchmark'

vector = Daru::Vector.new(
  (10**6).times.map.to_a.shuffle,
  missing_values: 100.times.map.to_a.shuffle
  )

vector = Daru::Vector.new(
  10000.times.map.to_a.shuffle,
  missing_values: 100.times.map.to_a.shuffle,
  )

Benchmark.bm do |x|
  x.report("Mean of a vector") do
    vector.mean
  end

  x.report("Minimum of a vector") do
    vector.min
  end
end

#                    ===== Benchmarks =====
#
#                                     user     system      total        real
# Mean of a vector                 0.130000   0.010000   0.140000 (  0.145534)
# Min of a vector                  0.150000   0.000000   0.150000 (  0.163623)
