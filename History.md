# Unreleased
* Faster `MultiIndex` lookups: `#[]`, `#pos` and `#positions_for` memoize their results, `.from_tuples` and
  `.from_arrays` find labels through a hash instead of scanning each level, and `#to_a` and `#key` no longer rebuild
  every level's keys on each call
* Faster single-row reads (`DataFrame#row[]`, `#row_at`, `#each_row` and their variants), which no longer go
  through `Vector#at`'s coercion and validation for each column
* `Vector#category?` no longer scans the vector's data
* Fixed `MultiIndex.from_arrays` and `.from_tuples` mapping a value to another one it is `==` but not `eql?` to,
  e.g. `1.0` to `1`

# 0.5.0
* [Breaking change] Removed `DateTimeIndex`, the date offsets and the `DaruLite::DAYS_OF_WEEK` and
  `DaruLite::MONTH_DAYS` constants. `Index.new` given `DateTime` objects now returns a plain `Index`
* [Breaking change] Removed the Excel, SQL, ActiveRecord and plain text readers and writers
  (`from_excel`, `write_excel`, `from_sql`, `write_sql`, `from_activerecord`, `from_plaintext`)
  and `DaruLite::IOHelpers.process_row`. CSV reading and writing is unchanged
* [Breaking change] Removed `DataFrame#save`, `Vector#save` and `DaruLite::IO.load`.
  `Marshal.dump` and `Marshal.load` still work on dataframes, vectors and indexes
* [Breaking change] Removed `#to_html` on `DataFrame`, `Vector` and `MultiIndex` and the IRuby templates
* [Breaking change] Removed the `which` DSL extension, which was never loaded by default
* [Breaking change] `Vector#acvf`'s `unbiased` argument was inverted and now means what it says: `true` divides
  lag k by n - k, `false` by n. Its default becomes `false`, so `acvf` without that argument returns the same values.
  Swap the value wherever it is passed explicitly
* Fixed `DataFrame#inspect` and `DataFrame#rotate_vectors` raising `NoMethodError` when ActiveSupport is not loaded
* Fixed `Marshal.load` raising `NoMethodError` on a `MultiIndex`, a `CategoricalIndex`, and any `Vector` or `DataFrame`
  built on one
* Fixed `DataFrame#inspect` raising `ArgumentError` on a DataFrame without vectors, and truncating
  `MultiIndex` vector names
* Fixed `Vector#proportion` for a value absent from the vector and for Integer/Float mismatches
* Fixed `Vector#percentile(100)` with the `:midpoint` strategy raising `TypeError`
* Fixed `Vector#skew`, `#kurtosis` and `#sum_of_squared_deviation` raising on vectors with missing values
* Fixed `Vector#index_of_max`, `#index_of_min` and their `_by` variants repeating an index for tied values
* Fixed `Vector#ema`, `#emv`, `#emsd` and `#macd` on vectors with `nil`, shorter than the window or with a custom index.
  A `nil` in the first window is now ignored instead of counting as 0
* Fixed `Vector#acvf` raising on short vectors and subtracting the mean when `demean` is false
* Added `DataFrame#reorder_rows`, which moves rows to given positions while keeping the index order
* Added `DataFrame#add_missing_vectors`, which adds the vectors a dataframe lacks, filled with `nil`
* Added `DataFrame#symbolize_vectors!`, `DataFrame#rename_blank_vectors!` and `DataFrame#rename_blank_rows!`
* Added `Vector#divide_or_zero`, a division returning `0.0` instead of failing when the divisor is zero or `nil`

# 0.4.0
* [Breaking change] Removed the methods deprecated since 2016:
  `Vector#has_missing_data?`, `#flawed?`, `#n_valid`, `#only_valid`, `#only_missing`, `#missing_positions` and `#freqs`,
  `DataFrame#has_missing_data?`, `#flawed?` and `#dup_only_valid`. Use `#include_values?`, `#count_values`,
  `#reject_values`, `#indexes` and `#frequencies` instead
* [Breaking change] Removed `DaruLite::Core::GroupBy.get_positions_group_map_on`, deprecated since 2019.
  Use `DaruLite::Core::GroupBy.group_by_index_to_positions` instead
* [Breaking change] Removed the global `jruby?` method, the `MDArray` class (whose `#daru_lite_vector` and `#dv`
  only raised `NotImplementedError`) and the `Object#itself` shim that daru Lite defined in every application
  loading it
* [Breaking change] `Vector.new(dtype: :mdarray)` raises `ArgumentError` instead of `NotImplementedError`
* [Breaking change] `DataFrame.new` given a Hash of vectors, an `:order` and `clone: false` raises `ArgumentError`
  when `:order` names a vector missing from the Hash (it used to relabel the vectors positionally) or lists
  the same vector twice (it used to raise `IndexError`)
* Fixed vectors extracted from a DataFrame built from a Hash of vectors having the wrong name or no name:
  they are now named after their column (#28)
* Fixed `DataFrame.new` with `clone: false` and an `:order` misaligning columns with their labels
* Deprecated `Array#daru_lite_vector`, `Array#dv`, `Array#to_index`, `Hash#daru_lite_vector`, `Hash#dv`,
  `Range#daru_lite_vector`, `Range#dv`, `Range#to_index` and `Matrix#elementwise_division`.
  They will be removed in a future release
* Deprecated `DataFrame#compute` with a String, which is `eval`'ed: pass a block instead.
  `DataFrame#compute` can now be called with a block only
* Deprecation warnings use Ruby's `:deprecated` category: enable them with `Warning[:deprecated] = true` or `ruby -w`

# 0.3.5
* Declared `csv` and `matrix` as runtime dependencies
* Fixed `Vector#standardize`, `Vector#to_json` and `DataFrame#to_json` raising `NoMethodError` when ActiveSupport is not loaded
* Required Ruby 3.4 or later
* Stopped packaging specs, fixtures, benchmarks and images in the gem
* CI now runs on Ruby 3.4 and 4.0

# 0.3.4 (2026-07-20)
* Fixed latently-broken `CategoricalIndex` methods relying on `@relation_hash`
* Fixed DataFrame operations on a `MultiIndex` with duplicate tuples

# 0.3.3 (2026-07-01)
* Fixed `keep_vector_if` `TypeError` on a `MultiIndex` with duplicate tuples, preserving the vectors' index type

# 0.3.2 (2026-06-12)
* Fixed `NoMethodError` on single-key lookup with a `CategoricalIndex`

# 0.3.1 (2026-04-17)
* Raise `IndexError` on duplicate (row, column) pairs when using `crosstab_by_assignation`

# 0.3.0 (2026-04-14)
* Preserve `nil` rows when using `crosstab_by_assignation`

# 0.2.4 (2026-04-10)
* Updated rubocop and fixed offenses

# 0.2.3 (2026-03-27)
* Fixed regression when accessing a `MultiIndex` vector with an array among the arguments

# 0.2.2 (2026-03-27)
* Fixed regression when accessing a `MultiIndex` with an array among the arguments

# 0.2.1 (2026-03-26)
* Fixed `DataFrame#union` and row subsets via `#[]` when using a `MultiIndex`
* Dropped Code Climate

# 0.2.0 (2025-04-21)
* Updated dependencies
* [Breaking change] Dropped DBI
* [Security] Fixed polynomial ReDoS

# 0.1.3 (2024-09-09)
* Fixed `DataFrame#keep_row_if`, `Index#to_a` and `MultiIndex#delete_at`

# 0.1.2 (2024-09-05)
* Split the `DataFrame` and `Vector` classes into modules
* Fixed `rotate_vectors` with vectors of mixed classes
* Fixed `keep_row_if` for categorical indexes

# 0.1.1 (2024-02-26)
* First version of the daru Lite readme
* Fixed `inspect` when vector names are integers
* Fixed `order=` when vectors are of different classes

# 0.1.0 (2024-02-16)
* Renamed the gem to daru_lite
* Dropped gruff
* Added `DataFrame#rotate_vectors!` and `DataFrame#add_level_to_vectors`
* Added column to categorical index conversion

# 0.0.1
* Forked from Daru
* Fixed incompatibilities with Ruby 3.1
* Removed plotting features
