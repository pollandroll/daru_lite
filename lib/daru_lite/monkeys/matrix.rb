class Matrix
  def elementwise_division(other)
    map.with_index do |e, index|
      e / other.to_a.flatten[index]
    end
  end
end
