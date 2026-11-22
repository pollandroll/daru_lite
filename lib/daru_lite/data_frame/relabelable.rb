module DaruLite
  class DataFrame
    module Relabelable
      # Converts every vector name to a Symbol, in place. With MultiIndex
      # vectors, every level of each name is converted.
      #
      # @return [DaruLite::DataFrame] self
      # @example
      #   df = DaruLite::DataFrame.new({ 'a' => [1, 2], 'b' => [3, 4] })
      #   df.symbolize_vectors!
      #   df.vectors.to_a #=> [:a, :b]
      def symbolize_vectors!
        self.vectors =
          if vectors.is_a?(DaruLite::MultiIndex)
            DaruLite::MultiIndex.from_tuples(vectors.to_a.map { |name| name.map(&:to_sym) })
          else
            DaruLite::Index.new(vectors.map(&:to_sym))
          end

        self
      end

      # Renames, in place, every vector whose name is blank (nil, false, empty
      # or made of whitespace only).
      #
      # As with #rename_vectors, a vector already named +label+ is overwritten,
      # and so is each blank vector by the next one: give blank vectors
      # distinct names first when several must be kept.
      #
      # @param label [Object] the name given to blank vectors
      # @return [DaruLite::DataFrame] self
      # @example
      #   df = DaruLite::DataFrame.new({ nil => [1, 2], b: [3, 4] })
      #   df.rename_blank_vectors!(:none)
      #   df.vectors.to_a #=> [:none, :b]
      def rename_blank_vectors!(label)
        vectors.to_a.each { |name| rename_vectors(name => label) if blank_label?(name) }

        self
      end

      # Renames, in place, every row whose index label is blank (nil, false,
      # empty or made of whitespace only).
      #
      # The first one is named +label+ and the following ones "label (1)",
      # "label (2)"... so that index labels stay unique. A row already named
      # +label+ takes part in the numbering. The index becomes a plain
      # DaruLite::Index; nothing changes when no label is blank.
      #
      # @param label [String] the label given to blank rows
      # @return [DaruLite::DataFrame] self
      # @example
      #   df = DaruLite::DataFrame.new({ a: [1, 2, 3] }, index: [nil, '', 'x'])
      #   df.rename_blank_rows!('none')
      #   df.index.to_a #=> ['none', 'none (1)', 'x']
      def rename_blank_rows!(label)
        return self if index.none? { |row_label| blank_label?(row_label) }

        count = -1
        self.index = DaruLite::Index.new(
          index.map do |row_label|
            next row_label unless blank_label?(row_label) || row_label == label

            count += 1
            count.zero? ? label : "#{label} (#{count})"
          end
        )

        self
      end

      private

      def blank_label?(label)
        return true if label.nil? || label == false
        return label.strip.empty? if label.is_a?(String)

        label.respond_to?(:empty?) && label.empty?
      end
    end
  end
end
