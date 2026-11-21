describe "Monkeys" do
  context Matrix do
    it "performs elementwise division" do
      left  = Matrix[[3,6,9],[4,8,12],[2,4,6]]
      right = Matrix[[3,6,9],[4,8,12],[2,4,6]]

      expect(left.elementwise_division(right)).to eq(Matrix[[1,1,1],[1,1,1],[1,1,1]])
    end
  end

  describe 'deprecations', :deprecation_warnings do
    it { expect { Matrix[[1]].elementwise_division(Matrix[[1]]) }.to output(/DEPRECATION: Matrix#elementwise_division/).to_stderr }
    it { expect { [1].daru_lite_vector }.to output(/DEPRECATION: Array#daru_lite_vector/).to_stderr }
    it { expect { [1].dv }.to output(/DEPRECATION: Array#daru_lite_vector/).to_stderr }
    it { expect { [1].to_index }.to output(/DEPRECATION: Array#to_index/).to_stderr }
    it { expect { (1..2).daru_lite_vector }.to output(/DEPRECATION: Range#daru_lite_vector/).to_stderr }
    it { expect { (1..2).to_index }.to output(/DEPRECATION: Range#to_index/).to_stderr }
    it { expect { { a: [1] }.daru_lite_vector }.to output(/DEPRECATION: Hash#daru_lite_vector/).to_stderr }

    it 'attributes the warning to the caller' do
      expect { [1].dv }.to output(/#{Regexp.escape(__FILE__)}/).to_stderr
    end
  end

  describe '#daru_lite_vector' do
    it 'converts Array' do
      expect([1,2,3].daru_lite_vector).to eq DaruLite::Vector.new [1,2,3]
      expect([1,2,3].daru_lite_vector('test', [:a, :b, :c])).to eq \
        DaruLite::Vector.new [1,2,3], name: 'test', index: [:a, :b, :c]
    end

    it 'converts Range' do
      expect((1..3).daru_lite_vector).to eq DaruLite::Vector.new [1,2,3]
      expect((1..3).daru_lite_vector('test', [:a, :b, :c])).to eq \
        DaruLite::Vector.new [1,2,3], name: 'test', index: [:a, :b, :c]
    end

    it 'converts Hash' do
      # FIXME: is it most useful way of converting hashes?..
      # I'd prefer something like
      #   expect({a: 1, b: 2, c: 3}.daru_lite_vector('test')).to eq DaruLite::Vector.new [1,2,3], name: 'test', index: [:a, :b, :c]
      #
      expect({test: [1, 2, 3]}.daru_lite_vector).to eq DaruLite::Vector.new [1,2,3], name: :test
    end
  end

  describe '#to_index' do
    it 'converts Array' do
      expect([1,2,3].to_index).to eq DaruLite::Index.new [1,2,3]
    end

    it 'converts Range' do
      expect((1..3).to_index).to eq DaruLite::Index.new [1,2,3]
    end
  end
end
