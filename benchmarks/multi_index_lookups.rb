$:.unshift File.expand_path("../../lib", __FILE__)

require 'benchmark'
require 'daru_lite'

# Many small tables with MultiIndex column labels, read cell by cell: the access pattern of
# crosstab-style reporting code (one row per answer, one column per (metric, segment) pair).
ROWS = 40
SEGMENTS = 25

def build_table
  segments = Array.new(SEGMENTS) { |i| "segment#{i}" }
  vectors = DaruLite::MultiIndex.from_tuples(
    %i[count percentage].product(segments)
  )
  index = DaruLite::Index.new([:base] + Array.new(ROWS) { |i| "answer#{i}" })
  DaruLite::DataFrame.new(
    Array.new(vectors.size) { Array.new(ROWS + 1) { rand(100) } },
    order: vectors,
    index: index
  )
end

tuples = Array.new(4000) { |i| ["q#{i % 50}", "item#{i % 400}", i] }
mi = DaruLite::MultiIndex.from_tuples(tuples)
df = build_table
segments = df[:percentage].vectors.to_a

Benchmark.bm(42) do |x|
  x.report("MultiIndex.from_tuples (4000 tuples)") { DaruLite::MultiIndex.from_tuples(tuples) }

  x.report("MultiIndex#to_a (4000 tuples)") { mi.to_a }

  x.report("MultiIndex#[] x1000 over 50 tuples") { 1000.times { |i| mi[tuples[i % 50]] } }

  x.report("Pairwise cell reads (#{ROWS}x#{SEGMENTS} table)") do
    segments.combination(2).each do |a, b|
      df.each_row_with_index do |row, label|
        next if label == :base

        base = df.row[:base]
        row[:percentage, a].to_f - row[:percentage, b].to_f + base[:count, a].to_f
      end
    end
  end
end

#                      ==== Benchmarks ====
#
# Ruby 4.0, Apple Silicon.
#                                                  user     system      total        real
# Before (0.5.0):
# MultiIndex.from_tuples (4000 tuples)         0.034853   0.000282   0.035135 (  0.035424)
# MultiIndex#to_a (4000 tuples)                0.015571   0.004011   0.019582 (  0.019627)
# MultiIndex#[] x1000 over 50 tuples           0.239431   0.001599   0.241030 (  0.241731)
# Pairwise cell reads (40x25 table)            0.671299   0.002969   0.674268 (  0.675086)
#
# After memoized MultiIndex lookups and the single-row fast path:
# MultiIndex.from_tuples (4000 tuples)         0.002966   0.000027   0.002993 (  0.002989)
# MultiIndex#to_a (4000 tuples)                0.000390   0.000008   0.000398 (  0.000398)
# MultiIndex#[] x1000 over 50 tuples           0.013642   0.000082   0.013724 (  0.013792)
# Pairwise cell reads (40x25 table)            0.199822   0.001586   0.201408 (  0.202215)
