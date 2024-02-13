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

    context ".from_excel" do
      before do
        id   = DaruLite::Vector.new([1, 2, 3, 4, 5, 6])
        name = DaruLite::Vector.new(%w(Alex Claude Peter Franz George Fernand))
        age  = DaruLite::Vector.new( [20, 23, 25, nil, 5.5, nil])
        city = DaruLite::Vector.new(['New York', 'London', 'London', 'Paris', 'Tome', nil])
        a1   = DaruLite::Vector.new(['a,b', 'b,c', 'a', nil, 'a,b,c', nil])
        @expected = DaruLite::DataFrame.new({
          :id => id, :name => name, :age => age, :city => city, :a1 => a1
          }, order: [:id, :name, :age, :city, :a1])
      end

      it "loads DataFrame from an Excel Spreadsheet" do
        df = DaruLite::DataFrame.from_excel 'spec/fixtures/test_xls.xls'

        expect(df.nrows).to eq(6)
        expect(df.vectors.to_a).to eq([:id, :name, :age, :city, :a1])
        expect(df[:age][5]).to eq(nil)
        expect(@expected).to eq(df)
      end
    end

    context "#from_excel with row_id" do
      before do
        id   = DaruLite::Vector.new(['id', 1.0, 2.0, 3.0, 4.0, 5.0, 6.0])
        name = DaruLite::Vector.new(%w(name Alex Claude Peter Franz George Fernand))
        age  = DaruLite::Vector.new(['age', 20.0, 23.0, 25.0, nil, 5.5, nil])
        city = DaruLite::Vector.new(['city', 'New York', 'London', 'London', 'Paris', 'Tome', nil])
        a1   = DaruLite::Vector.new(['a1', 'a,b', 'b,c', 'a', nil, 'a,b,c', nil])
        @expected_1 = DaruLite::DataFrame.new({:id2 => id, :name2 => name, :age2 => age}, order: [:id2, :name2, :age2])
        @expected_2 = DaruLite::DataFrame.new({
          :id => id, :name => name, :age => age, :city => city, :a1 => a1
          }, order: [:id, :name, :age, :city, :a1])
      end

      it "loads DataFrame from test_xls_2.xls" do
        df = DaruLite::DataFrame.from_excel 'spec/fixtures/test_xls_2.xls'

        expect(df.nrows).to eq(7)
        expect(df.vectors.to_a).to eq([:id2, :name2, :age2])
        expect(df[:age2][6]).to eq(nil)
        expect(@expected_1).to eq(df)
      end

      it "loads DataFrame from test_xls_2.xls with row_id" do
        df = DaruLite::DataFrame.from_excel 'spec/fixtures/test_xls_2.xls', {row_id: 1}

        expect(df.nrows).to eq(7)
        expect(df.vectors.to_a).to eq([:id, :name, :age, :city, :a1])
        expect(df[:age][6]).to eq(nil)
        expect(@expected_2).to eq(df)
      end
    end

    context "#write_excel" do
      before do
        a   = DaruLite::Vector.new(100.times.map { rand(100) })
        b   = DaruLite::Vector.new((['b'] * 100))
        @expected = DaruLite::DataFrame.new({ :b => b, :a => a })

        tempfile = Tempfile.new('test_write.xls')

        @expected.write_excel tempfile.path
        @df = DaruLite::DataFrame.from_excel tempfile.path
      end

      it "correctly writes DataFrame to an Excel Spreadsheet" do
        expect(@expected).to eq(@df)
      end
    end

    context ".from_sql" do
      include_context 'with accounts table in sqlite3 database'

      context 'with a database handler of DBI' do
        let(:db) do
          DBI.connect("DBI:SQLite3:#{db_name}")
        end

        subject { DaruLite::DataFrame.from_sql(db, "select * from accounts") }

        it "loads data from an SQL database" do
          accounts = subject
          expect(accounts.class).to eq DaruLite::DataFrame
          expect(accounts.nrows).to eq 2
          expect(accounts.row[0][:id]).to eq 1
          expect(accounts.row[0][:name]).to eq "Homer"
        end
      end

      context 'with a database connection of ActiveRecord' do
        let(:connection) do
          DaruLite::RSpec::Account.establish_connection "sqlite3:#{db_name}"
          DaruLite::RSpec::Account.connection
        end

        subject do
          DaruLite::DataFrame.from_sql(connection, "select * from accounts")
        end

        it "loads data from an SQL database" do
          accounts = subject
          expect(accounts.class).to eq DaruLite::DataFrame
          expect(accounts.nrows).to eq 2
          expect(accounts.row[0][:id]).to eq 1
          expect(accounts.row[0][:name]).to eq "Homer"
        end
      end
    end

    context "#write_sql" do
      let(:df) { DaruLite::DataFrame.new({
          'a' => [1,2,3,4,5],
          'b' => [11,22,33,44,55],
          'c' => ['a', 'g', 4, 5,'addadf'],
          'd' => [nil, 23, 4,'a','ff']})
      }

      let(:dbh) { double }
      let(:prepared_query) { double }

      it "writes the DataFrame to an SQL database" do
        expect(dbh).to receive(:prepare)
          .with('INSERT INTO tbl (a,b,c,d) VALUES (?,?,?,?)')
          .and_return(prepared_query)
        df.each_row { |r| expect(prepared_query).to receive(:execute).with(*r.to_a).ordered }

        df.write_sql dbh, 'tbl'
      end
    end

    context '.from_activerecord' do
      include_context 'with accounts table in sqlite3 database'

      context 'with ActiveRecord::Relation' do
        before do
          DaruLite::RSpec::Account.establish_connection "sqlite3:#{db_name}"
        end

        let(:relation) do
          DaruLite::RSpec::Account.all
        end

        context 'without specifying field names' do
          subject do
            DaruLite::DataFrame.from_activerecord(relation)
          end

          it 'loads data from an AR::Relation object' do
            accounts = subject
            expect(accounts.class).to eq DaruLite::DataFrame
            expect(accounts.nrows).to eq 2
            expect(accounts.vectors.to_a).to eq [:id, :name, :age]
            expect(accounts.row[0][:id]).to eq 1
            expect(accounts.row[0][:name]).to eq 'Homer'
            expect(accounts.row[0][:age]).to eq 20
          end
        end

        context 'with specifying field names in parameters' do
          subject do
            DaruLite::DataFrame.from_activerecord(relation, :name, :age)
          end

          it 'loads data from an AR::Relation object' do
            accounts = subject
            expect(accounts.class).to eq DaruLite::DataFrame
            expect(accounts.nrows).to eq 2
            expect(accounts.vectors.to_a).to eq [:name, :age]
            expect(accounts.row[0][:name]).to eq 'Homer'
            expect(accounts.row[0][:age]).to eq 20
          end
        end
      end
    end

    context ".from_plaintext" do
      it "reads data from plain text files" do
        df = DaruLite::DataFrame.from_plaintext 'spec/fixtures/bank2.dat', [:v1,:v2,:v3,:v4,:v5,:v6]

        expect(df.vectors.to_a).to eq([:v1,:v2,:v3,:v4,:v5,:v6])
      end

      xit "understands empty fields" do
        pending 'See FIXME note in io.rb'

        df = DaruLite::DataFrame.from_plaintext 'spec/fixtures/empties.dat', [:v1,:v2,:v3]

        expect(df.row[1].to_a).to eq [4, nil, 6]
      end

      it "understands non-numeric fields" do
        df = DaruLite::DataFrame.from_plaintext 'spec/fixtures/strings.dat', [:v1,:v2,:v3]

        expect(df[:v1].to_a).to eq ['test', 'foo']
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
        dataframe = DaruLite::Vector.new({a: vector, b: vector, c: vector})
        expect(Marshal.load(Marshal.dump(dataframe))).to eq(dataframe)
      end
    end

    context "#save" do
      before do
        @data_frame = DaruLite::DataFrame.new({b: [11,12,13,14,15], a: [1,2,3,4,5],
          c: [11,22,33,44,55]},
          order: [:a, :b, :c],
          index: [:one, :two, :three, :four, :five])
      end

      it "saves df to a file" do
        outfile = Tempfile.new('dataframe.df')
        @data_frame.save(outfile.path)
        a = DaruLite::IO.load(outfile.path)
        expect(a).to eq(@data_frame)
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

    context "#save" do
      ALL_DTYPES.each do |dtype|
        it "saves to a file and returns the same Vector of type #{dtype}" do
          vector = DaruLite::Vector.new(
              [5, 5, 5, 5, 5, 6, 6, 7, 8, 9, 10, 1, 2, 3, 4, 11, -99, -99],
              dtype: dtype)
          outfile = Tempfile.new('vector.vec')
          vector.save(outfile.path)
          expect(DaruLite::IO.load(outfile.path)).to eq(vector)
        end
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
