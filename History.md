# 0.4.0
* [Breaking change] Removed the methods deprecated since 2016:
  `Vector#has_missing_data?`, `#flawed?`, `#n_valid`, `#only_valid`, `#only_missing`, `#missing_positions` and `#freqs`,
  `DataFrame#has_missing_data?`, `#flawed?` and `#dup_only_valid`. Use `#include_values?`, `#count_values`,
  `#reject_values`, `#indexes` and `#frequencies` instead
* [Breaking change] Removed the global `jruby?` method, the empty `MDArray` class and the `Object#itself` shim
  that daru Lite defined in every application loading it
* [Breaking change] `Vector.new(dtype: :mdarray)` raises `ArgumentError` instead of `NotImplementedError`
* Deprecated `Array#daru_lite_vector`, `Array#dv`, `Array#to_index`, `Hash#daru_lite_vector`, `Hash#dv`,
  `Range#daru_lite_vector`, `Range#dv`, `Range#to_index` and `Matrix#elementwise_division`.
  They will be removed in 1.0
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
