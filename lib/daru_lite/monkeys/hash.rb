class Hash
  def daru_lite_vector(index = nil, dtype = :array)
    DaruLite.deprecation_warning(
      'Hash#daru_lite_vector and Hash#dv will be removed in 1.0, use DaruLite::Vector.new instead'
    )
    DaruLite::Vector.new values[0], name: keys[0], index: index, dtype: dtype
  end

  alias dv daru_lite_vector
end
