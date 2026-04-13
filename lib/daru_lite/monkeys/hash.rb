class Hash
  def daru_lite_vector(index = nil, dtype = :array)
    DaruLite::Vector.new values[0], name: keys[0], index: index, dtype: dtype
  end

  alias dv daru_lite_vector
end
