class Range
  def daru_lite_vector(name = nil, index = nil, dtype = :array)
    DaruLite::Vector.new self, name: name, index: index, dtype: dtype
  end

  alias dv daru_lite_vector

  def to_index
    DaruLite::Index.new to_a
  end
end
