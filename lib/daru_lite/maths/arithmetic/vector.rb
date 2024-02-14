module DaruLite
  module Maths
    module Arithmetic
      module Vector
        def +(other)
          binary_op :+, other
        end

        def -(other)
          binary_op :-, other
        end

        def *(other)
          binary_op :*, other
        end

        def /(other)
          binary_op :/, other
        end

        def %(other)
          binary_op :%, other
        end

        def **(other)
          binary_op :**, other
        end

        def exp
          math_unary_op :exp
        end

        def sqrt
          math_unary_op :sqrt
        end

        def abs
          recode { |e| e&.abs }
        end

        def round(precision = 0)
          recode { |e| e&.round(precision) }
        end

        # Add specified vector.
        #
        # @param other [DaruLite::Vector] The vector thats added to this.
        # @param opts [Boolean] :skipnil if true treats nils as 0.
        #
        # @example
        #
        #    v0 = DaruLite::Vector.new [1, 2, nil, nil]
        #    v1 = DaruLite::Vector.new [2, 1, 3, nil]
        #
        #    irb> v0.add v1
        #    =>  #<DaruLite::Vector(4)>
        #          0   3
        #          1   3
        #          2 nil
        #          3 nil
        #
        #    irb> v0.add v1, skipnil: true
        #    =>  #<DaruLite::Vector(4)>
        #          0   3
        #          1   3
        #          2   3
        #          3   0
        #
        def add(other, opts = {})
          v2v_binary :+, other, skipnil: opts.fetch(:skipnil, false)
        end

        private

        def math_unary_op(operation)
          recode { |e| Math.send(operation, e) unless e.nil? }
        end

        def binary_op(operation, other)
          case other
          when DaruLite::Vector
            v2v_binary operation, other
          else
            v2o_binary operation, other
          end
        end

        def v2o_binary(operation, other)
          DaruLite::Vector.new map { |e| e&.send(operation, other) },
                               name: @name, index: @index
        end

        def v2v_binary(operation, other, opts = {})
          # FIXME: why the sorting?.. - zverok, 2016-05-18
          index = ArrayHelper.sort_composite_data(@index.to_a | other.index.to_a)

          elements = index.map do |idx|
            this = self.index.include?(idx) ? self[idx] : nil
            that = other.index.include?(idx) ? other[idx] : nil
            this, that = zero_nil_args(this, that, opts.fetch(:skipnil, false))
            this && that ? this.send(operation, that) : nil
          end

          DaruLite::Vector.new(elements, name: @name, index: index)
        end

        def zero_nil_args(this, that, skipnil)
          if skipnil
            this = 0 if this.nil?
            that = 0 if that.nil?
          end
          [this, that]
        end
      end
    end
  end
end
