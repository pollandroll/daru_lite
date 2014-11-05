module Daru
  module Math
    module Arithmetic
      module Vector
        def + other
          case other
          when Daru::Vector
            v2v_binary :+, other
          else
            Daru::Vector.new self.map { |e| e + other }, name: @name, index: @index
          end
        end

        def - other
          case other
          when Daru::Vector
            v2v_binary :-, other
          else
            Daru::Vector.new self.map { |e| e - other }, name: @name, index: @index
          end
        end

        def * other
          case other
          when Daru::Vector
            v2v_binary :*, other
          else
            Daru::Vector.new self.map { |e| e * other }, name: @name, index: @index
          end
        end

        def / other
          case other
          when Daru::Vector
            v2v_binary :/, other
          else
            Daru::Vector.new self.map { |e| e / other }, name: @name, index: @index
          end
        end

        def % other
          case other
          when Daru::Vector
            v2v_binary :%, other
          else
            Daru::Vector.new self.map { |e| e % other }, name: @name, index: @index
          end
        end

       private

        def v2v_binary operation, other
          common_idxs = []
          elements    = []

          @index.each do |idx|
            this = self[idx]
            that = other[idx]

            if this and that
              elements << this.send(operation ,that)
              common_idxs << idx
            end
          end

          Daru::Vector.new(elements, name: @name, index: common_idxs)
        end
      end
    end
  end
end