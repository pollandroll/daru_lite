class Range
  def daru_lite_vector(name = nil, index = nil, dtype = :array)
    DaruLite.deprecation_warning(
      'Range#daru_lite_vector and Range#dv will be removed in 1.0, use DaruLite::Vector.new instead'
    )
    DaruLite::Vector.new self, name: name, index: index, dtype: dtype
  end

  alias dv daru_lite_vector

  def to_index
    DaruLite.deprecation_warning('Range#to_index will be removed in 1.0, use DaruLite::Index.new instead')
    DaruLite::Index.new to_a
  end
end
