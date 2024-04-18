module DaruLite
  class Vector
    module Aggregatable
      def group_by(*args)
        to_df.group_by(*args)
      end
    end
  end
end
