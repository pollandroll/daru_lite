module DaruLite
  module Maths
    module Statistics
      module Vector
        # Differences, rolling and exponential statistics, autocorrelation.
        module TimeSeries
          # The percent_change method computes the percent change over
          # the given number of periods.
          #
          # @param [Integer] periods (1) number of nils to insert at the beginning.
          #
          # @example
          #
          #   vector = DaruLite::Vector.new([4,6,6,8,10],index: ['a','f','t','i','k'])
          #   vector.percent_change
          #   #=>
          #   #   <DaruLite::Vector:28713060 @name = nil size: 5 >
          #   #              nil
          #   #   a
          #   #   f	   0.5
          #   #   t	   0.0
          #   #   i	   0.3333333333333333
          #   #   k          0.25
          def percent_change(periods = 1)
            must_be_numeric!

            prev = nil
            arr = @data.each_with_index.map do |cur, i|
              if i < periods ||
                 include_with_nan?(DaruLite::MISSING_VALUES, cur) ||
                 include_with_nan?(DaruLite::MISSING_VALUES, prev)
                nil
              else
                (cur - prev) / prev.to_f
              end.tap { prev = cur if cur }
            end

            DaruLite::Vector.new(arr, index: @index, name: @name)
          end

          # Performs the difference of the series.
          # Note: The first difference of series is X(t) - X(t-1)
          # But, second difference of series is NOT X(t) - X(t-2)
          # It is the first difference of the first difference
          # => (X(t) - X(t-1)) - (X(t-1) - X(t-2))
          #
          # == Arguments
          #
          # * *max_lags*: integer, (default: 1), number of differences reqd.
          #
          # @example Using #diff
          #
          #   ts = DaruLite::Vector.new((1..10).map { rand })
          #            # => [0.69, 0.23, 0.44, 0.71, ...]
          #
          #   ts.diff   # => [nil, -0.46, 0.21, 0.27, ...]
          #
          # @return [DaruLite::Vector]
          def diff(max_lags = 1)
            ts = self
            difference = []
            max_lags.times do
              difference = ts - ts.lag
              ts = difference
            end
            difference
          end

          # Calculate the rolling function for a loopback value.
          #
          # @param [Symbol] function The rolling function to be applied. Can be
          #   any function applicatble to DaruLite::Vector (:mean, :median, :count,
          #   :min, :max, etc.)
          # @param [Integer] n (10) A non-negative value which serves as the loopback length.
          # @return [DaruLite::Vector] Vector containin rolling calculations.
          # @example Using #rolling
          #   ts = DaruLite::Vector.new((1..100).map { rand })
          #            # => [0.69, 0.23, 0.44, 0.71, ...]
          #   # first 9 observations are nil
          #   ts.rolling(:mean)    # => [ ... nil, 0.484... , 0.445... , 0.513 ... , ... ]
          def rolling(function, n = 10)
            DaruLite::Vector.new(
              ([nil] * (n - 1)) +
              (0..(size - n)).map do |i|
                DaruLite::Vector.new(@data[i...(i + n)]).send(function)
              end, index: @index
            )
          end

          # @!method rolling_mean
          #   Calculate rolling average
          #   @yieldparam [Integer] n (10) Loopback length
          # @!method rolling_median
          #   Calculate rolling median
          #   @yieldparam [Integer] n (10) Loopback length
          # @!method rolling_count
          #   Calculate rolling non-missing count
          #   @yieldparam [Integer] n (10) Loopback length
          # @!method rolling_max
          #   Calculate rolling max value
          #   @yieldparam [Integer] n (10) Loopback length
          # @!method rolling_min
          #   Calculate rolling min value
          #   @yieldparam [Integer] n (10) Loopback length
          # @!method rolling_sum
          #   Calculate rolling sum
          #   @yieldparam [Integer] n (10) Loopback length
          # @!method rolling_std
          #   Calculate rolling standard deviation
          #   @yieldparam [Integer] n (10) Loopback length
          # @!method rolling_variance
          #   Calculate rolling variance
          #   @yieldparam [Integer] n (10) Loopback length
          %i[count mean median max min sum std variance].each do |meth|
            define_method(:"rolling_#{meth}") do |n = 10|
              rolling(meth, n)
            end
          end

          # Exponential Moving Average.
          # Calculates an exponential moving average of the series using a
          # specified parameter. If wilder is false (the default) then the EMA
          # uses a smoothing value of 2 / (n + 1), if it is true then it uses the
          # Welles Wilder smoother of 1 / n.
          #
          # Warning for EMA usage: EMAs are unstable for small series, as they
          # use a lot more than n observations to calculate. The series is stable
          # if the size of the series is >= 3.45 * (n + 1)
          #
          # @param [Integer] n (10) Loopback length.
          # @param [TrueClass, FalseClass] wilder (false) If true, 1/n value is
          #   used for smoothing; if false, uses 2/(n+1) value
          #
          # @example Using ema
          #
          #   ts = DaruLite::Vector.new((1..100).map { rand })
          #            # => [0.577..., 0.123..., 0.173..., 0.233..., ...]
          #
          #   # first 9 observations are nil
          #   ts.ema   # => [ ... nil, 0.455... , 0.395..., 0.323..., ... ]
          #
          # @return [DaruLite::Vector] Contains EMA
          def ema(n = 10, wilder = false)
            smoother = wilder ? 1.0 / n : 2.0 / (n + 1)
            # need to start everything from the first non-nil observation
            start = @data.index { |i| !i.nil? }
            return DaruLite::Vector.new([nil] * size, index: @index, name: @name) if start.nil?

            # nth observation is just a moving average
            last = @data[start...(start + n)].inject(0.0) { |s, a| a.nil? ? s : s + a } / n
            # first n - 1 observations are nil
            base = ([nil] * (start + n - 1)) << last
            # nil observations are skipped: they yield nil and leave the average as is
            (start + n).upto size - 1 do |i|
              x = self[i]
              base << (x.nil? ? nil : last = (x * smoother) + ((1 - smoother) * last))
            end

            DaruLite::Vector.new(base, index: @index, name: @name)
          end

          # Exponential Moving Variance.
          # Calculates an exponential moving variance of the series using a
          # specified parameter. If wilder is false (the default) then the EMV
          # uses a smoothing value of 2 / (n + 1), if it is true then it uses the
          # Welles Wilder smoother of 1 / n.
          #
          # @param [Integer] n (10) Loopback length.
          # @param [TrueClass, FalseClass] wilder (false) If true, 1/n value is
          #   used for smoothing; if false, uses 2/(n+1) value
          #
          # @example Using emv
          #
          #   ts = DaruLite::Vector.new((1..100).map { rand })
          #            # => [0.047..., 0.23..., 0.836..., 0.845..., ...]
          #
          #   # first 9 observations are nil
          #   ts.emv   # => [ ... nil, 0.073... , 0.082..., 0.080..., ...]
          #
          # @return [DaruLite::Vector] contains EMV
          def emv(n = 10, wilder = false) # rubocop:disable Metrics/AbcSize
            smoother = wilder ? 1.0 / n : 2.0 / (n + 1)
            # need to start everything from the first non-nil observation
            start = @data.index { |i| !i.nil? }
            return DaruLite::Vector.new([nil] * size, index: @index, name: @name) if start.nil?

            mean = @data[start...(start + n)].inject(0.0) { |s, a| a.nil? ? s : s + a } / n
            # nth observation is just a moving variance_population
            var = @data[start...(start + n)].inject(0.0) { |s, x| x.nil? ? s : s + ((x - mean)**2) } / n
            # first n - 1 observations are nil
            var_base = ([nil] * (start + n - 1)) << var
            # nil observations are skipped: they yield nil and leave mean and variance as they are
            (start + n).upto size - 1 do |i|
              x = self[i]
              next var_base << nil if x.nil?

              last = mean
              mean = (x * smoother) + ((1 - smoother) * last)
              var_base << (var = ((1 - smoother) * var) + (smoother * (x - last) * (x - mean)))
            end
            DaruLite::Vector.new(var_base, index: @index, name: @name)
          end

          # Exponential Moving Standard Deviation.
          # Calculates an exponential moving standard deviation of the series using a
          # specified parameter. If wilder is false (the default) then the EMSD
          # uses a smoothing value of 2 / (n + 1), if it is true then it uses the
          # Welles Wilder smoother of 1 / n.
          #
          # @param [Integer] n (10) Loopback length.
          # @param [TrueClass, FalseClass] wilder (false) If true, 1/n value is
          #   used for smoothing; if false, uses 2/(n+1) value
          #
          # @example Using emsd
          #
          #   ts = DaruLite::Vector.new((1..100).map { rand })
          #            # => [0.400..., 0.727..., 0.862..., 0.013..., ...]
          #
          #   # first 9 observations are nil
          #   ts.emsd   # => [ ... nil, 0.285... , 0.258..., 0.243..., ...]
          #
          # @return [DaruLite::Vector] contains EMSD
          def emsd(n = 10, wilder = false)
            result = []
            emv_return = emv(n, wilder)
            emv_return.each do |d| # rubocop:disable Style/MapIntoArray
              result << (d.nil? ? nil : Math.sqrt(d))
            end
            DaruLite::Vector.new(result, index: @index, name: @name)
          end

          # Moving Average Convergence-Divergence.
          # Calculates the MACD (moving average convergence-divergence) of the time
          # series.
          # @see https://en.wikipedia.org/wiki/MACD
          #
          # @param fast [Integer] fast period of MACD (default 12)
          # @param slow [Integer] slow period of MACD (default 26)
          # @param signal [Integer] signal period of MACD (default 9)
          #
          # @example Create a series and calculate MACD values
          #   ts = DaruLite::Vector.new((1..100).map { rand })
          #            # => [0.69, 0.23, 0.44, 0.71, ...]
          #   macdseries, macdsignal, macdhist = ts.macd
          #   macdseries, macdsignal, macdhist = ts.macd(13)
          #   macdseries, macdsignal, macdhist = ts.macd(signal=5)
          #
          # @return [Array<DaruLite::Vector>] macdseries, macdsignal and macdhist are
          #   returned as an array of three DaruLite::Vectors
          #
          def macd(fast = 12, slow = 26, signal = 9)
            macdseries = ema(fast) - ema(slow)
            macdsignal = macdseries.ema(signal)
            macdhist = macdseries - macdsignal
            [macdseries, macdsignal, macdhist]
          end

          # Calculates the autocorrelation coefficients of the series.
          #
          # The first element is always 1, since that is the correlation
          # of the series with itself.
          #
          # @example
          #   ts = DaruLite::Vector.new((1..100).map { rand })
          #
          #   ts.acf   # => array with first 21 autocorrelations
          #   ts.acf 3 # => array with first 3 autocorrelations
          def acf(max_lags = nil)
            max_lags ||= (10 * Math.log10(size)).to_i

            (0..max_lags).map do |i|
              if i.zero?
                1.0
              else
                m = mean
                # can't use Pearson coefficient since the mean for the lagged series should
                # be the same as the regular series
                ((self - m) * (lag(i) - m)).sum / variance_sample / (size - 1)
              end
            end
          end

          # Provides autocovariance.
          #
          # == Options
          #
          # * *:demean* = true; optional. Supply false if series is not to be demeaned
          # * *:unbiased* = true; optional. true/false for unbiased/biased form of autocovariance
          #
          # == Returns
          #
          # Autocovariance value
          def acvf(demean = true, unbiased = true)
            demeaned_series = demean ? self - mean : self

            n = [(10 * Math.log10(size)).to_i + 1, size].min
            m = mean
            d = if unbiased
                  Array.new(size, size)
                else
                  (1..size).to_a.reverse[0..n]
                end

            0.upto(n - 1).map do |i|
              (demeaned_series * (demean ? lag(i) - m : lag(i))).sum.fdiv(d[i])
            end
          end

          # Calculate cumulative sum of Vector
          def cumsum
            result = []
            acc = 0
            @data.each do |d|
              if include_with_nan? DaruLite::MISSING_VALUES, d
                result << nil
              else
                acc += d
                result << acc
              end
            end

            DaruLite::Vector.new(result, index: @index)
          end
        end
      end
    end
  end
end
