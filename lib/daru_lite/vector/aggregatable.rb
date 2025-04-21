module DaruLite
  class Vector
    module Aggregatable
      def group_by(*)
        to_df.group_by(*)
      end
    end
  end
end
