class MDArray
  def daru_lite_vector(name = nil, index = nil, *)
    DaruLite::Vector.new self, name: name, index: index, dtype: :mdarray
  end

  alias dv daru_lite_vector
end
