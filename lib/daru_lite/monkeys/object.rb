class Object
  if RUBY_VERSION < '2.2'
    def itself
      self
    end
  end
end
