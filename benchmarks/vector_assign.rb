$:.unshift File.expand_path("../../lib", __FILE__)

require 'benchmark'
require 'daru_lite'

df = DaruLite::DataFrame.new({
  a: 100000.times.map { rand },
  b: 100000.times.map { rand },
  c: 100000.times.map { rand }
})

index = DaruLite::Index.new((0...100000).to_a.shuffle)

Benchmark.bm do |x|
  x.report("Assign new vector as Array") do
    df[:d] = 100000.times.map { rand }
  end

  x.report("Reassign same vector as Array") do
    df[:a] = 100000.times.map { rand }
  end

  x.report("Assign new Vector as DaruLite::Vector") do
    df[:e] = DaruLite::Vector.new(100000.times.map { rand })
  end

  x.report("Reassign same Vector as DaruLite::Vector") do
    df[:b] = DaruLite::Vector.new(100000.times.map { rand })
  end

  x.report("Reassgin differently indexed DaruLite::Vector") do
    df[:b] = DaruLite::Vector.new(100000.times.map { rand }, index: index)
  end
end

#                           ===== Benchmarks =====
#                                             user     system      total        real
# Assign new vector as Array                0.370000   0.000000   0.370000 (0.364515)
# Reassign same vector as Array             0.470000   0.000000   0.470000 (0.471408)
# Assign new Vector as DaruLite::Vector         0.940000   0.000000   0.940000 (0.947879)
# Reassign same Vector as DaruLite::Vector      0.760000   0.020000   0.780000 (0.769969)
# Reassgin differently indexed DaruLite::Vector <Too embarassingly slow.>
