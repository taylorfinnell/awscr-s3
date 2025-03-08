module Awscr
  module S3
    module Presigned
      # A field in a `Presigned::Post`
      class PostField
        include Comparable(PostField)

        # The key of the field
        getter key

        # The value of the field
        getter value

        def initialize(@key : String, @value : String)
        end

        # Serialize the key into the format required for a `Presigned::Post`
        def serialize
          {@key => @value}
        end

        def <=>(other : PostField)
          if @key == other.key && @value == other.value
            0
          else
            -1
          end
        end
      end
    end
  end
end
