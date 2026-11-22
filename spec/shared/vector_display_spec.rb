describe DaruLite::Vector do
  # TODO: Add inspect specs for category
  context '#inspect' do
    context 'simple' do
      subject(:vector) { DaruLite::Vector.new [1,2,3],
        index: [:a, :b, :c], name: 'test'}
      its(:inspect) { is_expected.to eq %Q{
        |#<DaruLite::Vector(3)>
        |      test
        |    a    1
        |    b    2
        |    c    3
      }.unindent }
    end

    context 'no name' do
      subject(:vector) { DaruLite::Vector.new [1,2,3], index: [:a, :b, :c]}
      its(:inspect) { is_expected.to eq %Q{
        |#<DaruLite::Vector(3)>
        |   a   1
        |   b   2
        |   c   3
      }.unindent }
    end

    context 'with nils' do
      subject(:vector) { DaruLite::Vector.new [1,nil,3],
        index: [:a, :b, :c], name: 'test'}
      its(:inspect) { is_expected.to eq %Q{
        |#<DaruLite::Vector(3)>
        |      test
        |    a    1
        |    b  nil
        |    c    3
      }.unindent }
    end

    context 'very large amount of data' do
      subject(:vector) { DaruLite::Vector.new [1,2,3] * 100, name: 'test'}
      its(:inspect) { is_expected.to eq %Q{
        |#<DaruLite::Vector(300)>
        |      test
        |    0    1
        |    1    2
        |    2    3
        |    3    1
        |    4    2
        |    5    3
        |    6    1
        |    7    2
        |    8    3
        |    9    1
        |   10    2
        |   11    3
        |   12    1
        |   13    2
        |   14    3
        |  ...  ...
      }.unindent }
    end

    context 'really long name or data' do
      subject(:vector) { DaruLite::Vector.new [1,2,'this is ridiculously long'],
        index: [:a, :b, :c], name: 'and this is not much better faithfully'}
      its(:inspect) { is_expected.to eq %Q{
        |#<DaruLite::Vector(3)>
        |                      and this is not much
        |                    a                    1
        |                    b                    2
        |                    c this is ridiculously
      }.unindent }
    end

    context 'with multiindex' do
      subject(:vector) {
        DaruLite::Vector.new(
          [1,2,3,4,5,6,7],
          name: 'test',
          index: DaruLite::MultiIndex.from_tuples([
              %w[foo one],
              %w[foo two],
              %w[foo three],
              %w[bar one],
              %w[bar two],
              %w[bar three],
              %w[baz one],
           ]),
        )
      }

      its(:inspect) { is_expected.to eq %Q{
        |#<DaruLite::Vector(7)>
        |              test
        |   foo   one     1
        |         two     2
        |       three     3
        |   bar   one     4
        |         two     5
        |       three     6
        |   baz   one     7
      }.unindent}
    end

    context 'threshold and spacing settings' do
    end
  end
end
