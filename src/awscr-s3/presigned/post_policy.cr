require "base64"
require "json"

module Awscr
  module S3
    module Presigned
      class Policy
        @expiration : Time?

        # The expiration time of this policy
        getter expiration

        # The policy fields
        getter fields

        def initialize
          @fields = FieldCollection.new
        end

        # The expiration time of the `Policy`.
        def expiration(time : Time | Nil)
          @expiration = time
        end

        # Returns true if the `Policy` is valid, false otherwise.
        def valid?
          # @todo check that the sig keys exist
          !!!@expiration.nil?
        end

        # Adds a `Condition` to the `Policy`.
        def condition(key : String, value : String | Int32)
          @fields.push(PostField.new(key, value))
          self
        end

        # Returns the hash Representation of the `Policy`. Returns an empty hash
        # if the `Policy` is not valid.
        def to_hash
          return {} of String => String unless valid?

          {
            "expiration" => @expiration.not_nil!.to_s("%Y-%m-%dT%H:%M:%S.000Z"),
            "conditions" => @fields.map(&.serialize),
          }
        end

        # Returns the `Policy` has Base64 encoded JSON.
        def to_s(io : IO)
          io << Base64.strict_encode(to_hash.to_json)
        end
      end
    end
  end
end
