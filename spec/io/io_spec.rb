# -*- coding: utf-8 -*-
describe DaruLite::IO do
  describe DaruLite::DataFrame do
    context ".from_csv" do
      before do
        %w[matrix_test repeated_fields scientific_notation sales-funnel].each do |file|
          WebMock
            .stub_request(:get,"http://example.com/#{file}.csv")
            .to_return(status: 200, body: File.read("spec/fixtures/#{file}.csv"))
        end
      end

      it "loads from a CSV file" do
        df = DaruLite::DataFrame.from_csv('spec/fixtures/matrix_test.csv',
          col_sep: ' ', headers: true)

        df.vectors = [:image_resolution, :true_transform, :mls].to_index
        expect(df.vectors).to eq([:image_resolution, :true_transform, :mls].to_index)
        expect(df[:image_resolution].first).to eq(6.55779)
        expect(df[:true_transform].first).to eq("-0.2362347,0.6308649,0.7390552,0,0.6523478,-0.4607318,0.6018043,0,0.7201635,0.6242881,-0.3027024,4262.65,0,0,0,1")
      end

      it "works properly for repeated headers" do
        df = DaruLite::DataFrame.from_csv('spec/fixtures/repeated_fields.csv',header_converters: :symbol)
        expect(df.vectors.to_a).to eq(["id", "name_1", "age_1", "city", "a1", "name_2", "age_2"])

        age = DaruLite::Vector.new([3, 4, 5, 6, nil, 8])
        expect(df['age_2']).to eq(age)
      end

      it "accepts scientific notation as float" do
        ds = DaruLite::DataFrame.from_csv('spec/fixtures/scientific_notation.csv', order: ['x', 'y'])
        expect(ds.vectors.to_a).to eq(['x', 'y'])
        y = [9.629587310436753e+127, 1.9341543147883677e+129, 3.88485279048245e+130]
        y.zip(ds['y']).each do |y_expected, y_ds|
          expect(y_ds).to be_within(0.001).of(y_expected)
        end
      end

      it "follows the order of columns given in CSV" do
        df = DaruLite::DataFrame.from_csv 'spec/fixtures/sales-funnel.csv'
        expect(df.vectors.to_a).to eq(%W[Account Name Rep Manager Product Quantity Price Status])
      end

      it "handles empty rows in the CSV" do
        df = DaruLite::DataFrame.from_csv 'spec/fixtures/empty_rows_test.csv'
        expect(df.nrows).to eq(13)
      end

      it "uses the custom boolean converter correctly" do
        df = DaruLite::DataFrame.from_csv 'spec/fixtures/boolean_converter_test.csv', converters: [:boolean]
        expect(df['Domestic'].to_a).to all be_boolean
      end

      it "uses the custom string converter correctly" do
        df = DaruLite::DataFrame.from_csv 'spec/fixtures/string_converter_test.csv', converters: [:string]
        expect(df['Case Number'].to_a.all? {|x| String === x }).to be_truthy
      end

      it "allow symbol to converters option" do
        df = DaruLite::DataFrame.from_csv 'spec/fixtures/boolean_converter_test.csv', converters: :boolean
        expect(df['Domestic'].to_a).to all be_boolean
      end

      it "checks for equal parsing of local CSV files and remote CSV files" do
        %w[matrix_test repeated_fields scientific_notation sales-funnel].each do |file|
          df_local  = DaruLite::DataFrame.from_csv("spec/fixtures/#{file}.csv")
          df_remote = DaruLite::DataFrame.from_csv("http://example.com/#{file}.csv")
          expect(df_local).to eq(df_remote)
        end
      end
    end

    context "#write_csv" do
      before do
        @df = DaruLite::DataFrame.new({
          'a' => [1,2,3,4,5],
          'b' => [11,22,33,44,55],
          'c' => ['a', 'g', 4, 5,'addadf'],
          'd' => [nil, 23, 4,'a','ff']})
        @tempfile = Tempfile.new('data.csv')

      end

      it "writes DataFrame to a CSV file" do
        @df.write_csv @tempfile.path
        expect(DaruLite::DataFrame.from_csv(@tempfile.path)).to eq(@df)
      end

      it "will write headers unless headers=false" do
        @df.write_csv @tempfile.path
        first_line = File.open(@tempfile.path, &:readline).chomp.split(',', -1)
        expect(first_line).to eq @df.vectors.to_a
      end

      it "will not write headers when headers=false" do
        @df.write_csv @tempfile.path, { headers: false }
        first_line = File.open(@tempfile.path, &:readline).chomp.split(',', -1)
        expect(first_line).to eq @df.head(1).map { |v| (v.first || '').to_s }
      end

    end

    context "JSON" do
      it "loads parsed JSON" do
        require 'json'

        json = File.read 'spec/fixtures/countries.json'
        df   = DaruLite::DataFrame.new JSON.parse(json)

        expect(df.vectors).to eq([
          'name', 'nativeName', 'tld', 'cca2', 'ccn3', 'cca3', 'currency', 'callingCode',
          'capital', 'altSpellings', 'relevance', 'region', 'subregion', 'language',
          'languageCodes', 'translations', 'latlng', 'demonym', 'borders', 'area'].to_index)

        expect(df.row[0]['name']).to eq("Afghanistan")
      end
    end

    context "Marshalling" do
      it "" do
        vector = DaruLite::Vector.new (0..100).collect { |_n| rand(100) }
        dataframe = DaruLite::DataFrame.new({a: vector, b: vector, c: vector}, name: :frame)
        expect(Marshal.load(Marshal.dump(dataframe))).to eq(dataframe)
      end
    end
  end

  describe DaruLite::Vector do
    context "Marshalling" do
      it "" do
        vector = DaruLite::Vector.new (0..100).collect { |_n| rand(100) }
        expect(Marshal.load(Marshal.dump(vector))).to eq(vector)
      end
    end
  end

  describe DaruLite::Index do
    context "Marshalling" do
      it "" do
        i = DaruLite::Index.new([:a, :b, :c, :d, :e])
        expect(Marshal.load(Marshal.dump(i))).to eq(i)
      end
    end
  end
end
