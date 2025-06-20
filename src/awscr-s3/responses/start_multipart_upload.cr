require "xml"

module Awscr::S3::Response
  class StartMultipartUpload < Base
    # Create a `StartMultipartUpload` response from an
    # `HTTP::Client::Response` object
    def self.from_response(response)
      xml = XML.new(response.body)

      bucket = xml.string("//InitiateMultipartUploadResult/Bucket")
      key = xml.string("//InitiateMultipartUploadResult/Key")
      upload_id = xml.string("//InitiateMultipartUploadResult/UploadId")

      new(bucket, key, upload_id, response.status, response.status_message, response.headers)
    end

    # The key for the object
    getter key

    # The bucket for the object
    getter bucket

    # The ID of the new object
    getter upload_id

    def initialize(
      @bucket : String,
      @key : String,
      @upload_id : String,
      @status : HTTP::Status,
      @status_message : String? = nil,
      @headers : HTTP::Headers = HTTP::Headers.new,
    )
    end

    def_equals @key, @bucket, @upload_id
  end
end
