class Matrix
  def elementwise_division(other)
    DaruLite.deprecation_warning(
      'Matrix#elementwise_division will be removed in a future release, use Matrix#combine instead'
    )
    map.with_index do |e, index|
      e / other.to_a.flatten[index]
    end
  end
end
