module DaruLite
  class DataFrame
    module Relabelable
      # Converts every String vector name to a Symbol, in place. Other names are
      # left as they are. With MultiIndex vectors, every level of each name is
      # converted.
      #
      # @raise [ArgumentError] when two vectors would end up with the same name
      # @return [DaruLite::DataFrame] self
      # @example
      #   df = DaruLite::DataFrame.new({ 'a' => [1, 2], 'b' => [3, 4] })
      #   df.symbolize_vectors!
      #   df.vectors.to_a #=> [:a, :b]
      def symbolize_vectors!
        multi_index = vectors.is_a?(DaruLite::MultiIndex)
        names = vectors.to_a.map do |name|
          multi_index ? name.map { |level| symbolize_label(level) } : symbolize_label(name)
        end
        ensure_unique_labels!(names)

        self.vectors = multi_index ? DaruLite::MultiIndex.from_tuples(names) : DaruLite::Index.new(names)

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
      # "label (2)"... skipping the numbers already taken by another row, so
      # that index labels stay unique. A row already named +label+ takes part
      # in the numbering. The index becomes a plain DaruLite::Index; nothing
      # changes when no label is blank.
      #
      # @param label [String] the label given to blank rows
      # @raise [ArgumentError] when the other labels are not unique, as a
      #   CategoricalIndex allows
      # @return [DaruLite::DataFrame] self
      # @example
      #   df = DaruLite::DataFrame.new({ a: [1, 2, 3] }, index: [nil, '', 'x'])
      #   df.rename_blank_rows!('none')
      #   df.index.to_a #=> ['none', 'none (1)', 'x']
      def rename_blank_rows!(label)
        labels = index.to_a
        return self if labels.none? { |row_label| blank_label?(row_label) }

        kept, renamed = labels.partition { |row_label| !blank_label?(row_label) && row_label != label }
        new_labels = numbered_labels(label, renamed.size, kept).each
        labels = labels.map { |row_label| kept.include?(row_label) ? row_label : new_labels.next }
        ensure_unique_labels!(labels)

        self.index = DaruLite::Index.new(labels)

        self
      end

      private

      # +label+, then "label (1)", "label (2)"... leaving out those in +taken+
      def numbered_labels(label, size, taken)
        candidates = Enumerator.produce(0) { |count| count + 1 }.lazy.map do |count|
          count.zero? ? label : "#{label} (#{count})"
        end

        candidates.reject { |candidate| taken.include?(candidate) }.first(size)
      end

      def symbolize_label(label)
        label.is_a?(String) ? label.to_sym : label
      end

      def ensure_unique_labels!(labels)
        duplicates = labels.tally.select { |_, count| count > 1 }.keys
        return if duplicates.empty?

        raise ArgumentError, "Labels must be unique, got duplicates: #{duplicates.map(&:inspect).join(', ')}"
      end

      def blank_label?(label)
        return true if label.nil? || label == false
        return label.strip.empty? if label.is_a?(String)

        label.respond_to?(:empty?) && label.empty?
      end
    end
  end
end
