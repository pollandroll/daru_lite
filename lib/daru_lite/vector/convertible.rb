module DaruLite
  class Vector
    module Convertible
      # @return [DaruLite::DataFrame] the vector as a single-vector dataframe
      def to_df
        DaruLite::DataFrame.new({ @name => @data }, name: @name, index: @index)
      end

      # Convert Vector to a horizontal or vertical Ruby Matrix.
      #
      # == Arguments
      #
      # * +axis+ - Specify whether you want a *:horizontal* or a *:vertical* matrix.
      def to_matrix(axis = :horizontal)
        case axis
        when :horizontal
          Matrix[to_a]
        when :vertical
          Matrix.columns([to_a])
        else
          raise ArgumentError, "axis should be either :horizontal or :vertical, not #{axis}"
        end
      end

      # Convert to hash (explicit). Hash keys are indexes and values are the correspoding elements
      def to_h
        @index.to_h { |index| [index, self[index]] }
      end

      # Return an array
      def to_a
        @data.to_a
      end

      # Convert the hash from to_h to json
      def to_json(*)
        to_h.to_json
      end

      # Convert to html for iruby
      def to_html(threshold = 30)
        table_thead = to_html_thead
        table_tbody = to_html_tbody(threshold)
        path = if index.is_a?(MultiIndex)
                 File.expand_path('../iruby/templates/vector_mi.html.erb', __dir__)
               else
                 File.expand_path('../iruby/templates/vector.html.erb', __dir__)
               end
        ERB.new(File.read(path).strip).result(binding)
      end

      def to_html_thead
        table_thead_path =
          if index.is_a?(MultiIndex)
            File.expand_path('../iruby/templates/vector_mi_thead.html.erb', __dir__)
          else
            File.expand_path('../iruby/templates/vector_thead.html.erb', __dir__)
          end
        ERB.new(File.read(table_thead_path).strip).result(binding)
      end

      def to_html_tbody(threshold = 30)
        table_tbody_path =
          if index.is_a?(MultiIndex)
            File.expand_path('../iruby/templates/vector_mi_tbody.html.erb', __dir__)
          else
            File.expand_path('../iruby/templates/vector_tbody.html.erb', __dir__)
          end
        ERB.new(File.read(table_tbody_path).strip).result(binding)
      end

      def to_s
        "#<#{self.class}#{": #{@name}" if @name}(#{size})#{':category' if category?}>"
      end
    end
  end
end
