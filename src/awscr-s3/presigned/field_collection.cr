require "./post_field"

module Awscr
  module S3
    module Presigned
      # Holds a collection of `PostField`s.
      #
      # ```
      # fields = FieldCollection.new
      # fields.to_a # => [] of PostField
      # field["test"] = "test"
      # field.push(PostField.new("Hi", "Hi"))
      # ```
      class FieldCollection
        include Enumerable(PostField)

        def initialize
          @fields = [] of PostField
        end

        # Adds a new `PostField` to the collection.
        def push(field : PostField)
          return false if @fields.includes?(field)
          @fields << field
          true
        end

        # Iterate over the collection's fields.
        def each(&block)
          @fields.each do |field|
            yield field
          end
        end

        # Access a key, by name, from the field collection. Returns the key if
        # found, otherwise returns nil.
        def [](key)
          self.find { |field| clean_key(field.key) == clean_key(key) }.try(&.value)
        end

        # Convert the collection to a hash in the form of key => value.
        def to_hash
          self.reduce({} of String => String) do |hash, field|
            hash[field.key] = field.value
            hash
          end
        end

        # :nodoc:
        private def clean_key(key)
          key.gsub("-", "_").downcase
        end
      end
    end
  end
end
