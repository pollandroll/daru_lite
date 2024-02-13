class Array
  def daru_lite_vector(name = nil, index = nil, dtype = :array)
    DaruLite::Vector.new self, name: name, index: index, dtype: dtype
  end

  alias dv daru_lite_vector

  def to_index
    DaruLite::Index.new self
  end
end

class Range
  def daru_lite_vector(name = nil, index = nil, dtype = :array)
    DaruLite::Vector.new self, name: name, index: index, dtype: dtype
  end

  alias dv daru_lite_vector

  def to_index
    DaruLite::Index.new to_a
  end
end

class Hash
  def daru_lite_vector(index = nil, dtype = :array)
    DaruLite::Vector.new values[0], name: keys[0], index: index, dtype: dtype
  end

  alias dv daru_lite_vector
end

class MDArray
  def daru_lite_vector(name = nil, index = nil, *)
    DaruLite::Vector.new self, name: name, index: index, dtype: :mdarray
  end

  alias dv daru_lite_vector
end

class Matrix
  def elementwise_division(other)
    map.with_index do |e, index|
      e / other.to_a.flatten[index]
    end
  end
end

class Object
  if RUBY_VERSION < '2.2'
    def itself
      self
    end
  end
end
# :nocov:
