module Awscr::S3::Response
  class BatchDeleteOutput
    class DeletedObject
      getter key
      getter code
      getter message

      def initialize(@key : String, @code : String, @message : String)
      end

      def deleted?
        @code.empty?
      end

      def_equals @key, @code, @message
    end

    # Create a `CompleteMultipartUpload` response from an
    # `HTTP::Client::Response` object
    def self.from_response(response)
      xml = XML.new(response.body)

      location = xml.string("//DeleteResult/Location")

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

    def success?
      !@objects.map(&.deleted?).includes?(false)
    end

    def deleted_objects
      @objects.select(&.deleted?)
    end

    def failed_objects
      @objects.reject(&.deleted?)
    end
  end
end
