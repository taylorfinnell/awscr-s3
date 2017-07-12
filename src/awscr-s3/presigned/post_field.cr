module Awscr
  module S3
    module Presigned
      # A field in a `Presigned::Post`
      abstract class PostField
        include Comparable(PostField)

        # The key of the field
        getter key

        # The value of the field
        getter value

        def initialize(@key : String, @value : String)
        end

        abstract def serialize

        def <=>(field : PostField)
          if @key == field.key && @value == field.value
            0
          else
            -1
          end
        end
      end

      # A field in the `Post` object
      class SimpleCondition < PostField
        def serialize
          {@key => @value}
        end
      end
    end
  end
end
