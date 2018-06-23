module Awscr::S3::Response
  class BatchDeleteOutput
    class DeletedObject
      # The key of the deleted object
      getter key

      # The failure code
      getter code

      # Human friendly failure message
      getter message

      def initialize(@key : String, @code : String, @message : String)
      end

      # Returns true of object was deleted, false otherwise
      def deleted?
        @code.empty?
      end

      def_equals @key, @code, @message
    end

    # Create a `CompleteMultipartUpload` response from an
    # `HTTP::Client::Response` object
    def self.from_response(response)
      xml = XML.new(response.body)

      xml.string("//DeleteResult/Location")

      objects = [] of DeletedObject
      xml.array("DeleteResult/Deleted") do |object|
        key = object.string("Key")
        code = object.string("Code")
        msg = object.string("Message")

        objects << DeletedObject.new(key, code, msg)
      end

      new(objects)
    end

    @objects : Array(DeletedObject)

    def initialize(objects)
      @objects = objects
    end

    # Returns true if all objects were deleted, false otherwise.
    def success?
      !@objects.map(&.deleted?).includes?(false)
    end

    # Returns an array of objects that were successfully deleted
    def deleted_objects
      @objects.select(&.deleted?)
    end

    # Returns an array of objects that failed to be deleted
    def failed_objects
      @objects.reject(&.deleted?)
    end
  end
end
