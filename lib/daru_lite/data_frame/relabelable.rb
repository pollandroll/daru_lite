module DaruLite
  class DataFrame
    module Relabelable
      # Converts every String vector name to a Symbol, in place. Other names are
      # left as they are. With MultiIndex vectors, every level of each name is
      # converted.
      #
      # @raise [ArgumentError] when the conversion gives two vectors the same name
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
        ensure_unique_labels!(names) if names.uniq.size < vectors.to_a.uniq.size

        symbolized = multi_index ? DaruLite::MultiIndex.from_tuples(names) : DaruLite::Index.new(names)
        symbolized.name = vectors.name if vectors.name
        self.vectors = symbolized

        self
      end

      # Renames, in place, every vector whose name is blank (nil, false, empty
      # or made of whitespace only).
      #
      # The first one is named +label+ and the following ones "label (1)",
      # "label (2)"... skipping the names already taken by another vector, so
      # that no vector is lost. Vectors that are not blank keep their name and
      # every vector keeps its position.
      #
      # @param label [String, Symbol] the name given to blank vectors, not blank itself
      # @raise [ArgumentError] when +label+ is blank
      # @raise [NotImplementedError] with MultiIndex vectors
      # @return [DaruLite::DataFrame] self
      # @example
      #   df = DaruLite::DataFrame.new({ nil => [1, 2], b: [3, 4], '' => [5, 6] })
      #   df.rename_blank_vectors!(:none)
      #   df.vectors.to_a #=> [:none, :b, :"none (1)"]
      def rename_blank_vectors!(label)
        raise ArgumentError, 'label must not be blank' if blank_label?(label)
        raise NotImplementedError, 'Cannot rename blank vectors under a MultiIndex' if vectors.is_a?(MultiIndex)

        names = replace_blank_labels(vectors.to_a, label)
        self.vectors = DaruLite::Index.new(names, name: vectors.name) unless names == vectors.to_a

        self
      end

      # Renames, in place, every row whose index label is blank (nil, false,
      # empty or made of whitespace only).
      #
      # The first one is named +label+ and the following ones "label (1)",
      # "label (2)"... skipping the labels already taken by another row, so
      # that index labels stay unique. Rows that are not blank keep their
      # label, including one already named +label+. The index becomes a plain
      # DaruLite::Index; nothing changes when no label is blank.
      #
      # @param label [String] the label given to blank rows, not blank itself
      # @raise [ArgumentError] when +label+ is blank, or when the other labels
      #   are not unique, as a CategoricalIndex allows
      # @return [DaruLite::DataFrame] self
      # @example
      #   df = DaruLite::DataFrame.new({ a: [1, 2, 3] }, index: [nil, '', 'x'])
      #   df.rename_blank_rows!('none')
      #   df.index.to_a #=> ['none', 'none (1)', 'x']
      def rename_blank_rows!(label)
        raise ArgumentError, 'label must not be blank' if blank_label?(label)

        labels = replace_blank_labels(index.to_a, label)
        return self if labels == index.to_a

        ensure_unique_labels!(labels)

        self.index = DaruLite::Index.new(labels, name: index.name)

        self
      end

      private

      def replace_blank_labels(labels, label)
        blank, kept = labels.partition { |candidate| blank_label?(candidate) }
        replacements = numbered_labels(label, blank.size, kept.to_set).each

        labels.map { |candidate| blank_label?(candidate) ? replacements.next : candidate }
      end

      # +label+, then "label (1)", "label (2)"... leaving out those in +taken+.
      # A Symbol label gives Symbols.
      def numbered_labels(label, size, taken)
        candidates = Enumerator.produce(0) { |count| count + 1 }.lazy.map do |count|
          next label if count.zero?

          numbered = "#{label} (#{count})"
          label.is_a?(Symbol) ? numbered.to_sym : numbered
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
        return label.to_s.match?(/\A[[:space:]]*\z/) if label.is_a?(String) || label.is_a?(Symbol)

        label.respond_to?(:empty?) && label.empty?
      end
    end
  end
end
