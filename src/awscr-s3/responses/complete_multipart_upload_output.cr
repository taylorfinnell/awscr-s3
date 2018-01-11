require "xml"

module Awscr::S3::Response
  class CompleteMultipartUpload
    # Create a `CompleteMultipartUpload` response from an
    # `HTTP::Client::Response` object
    def self.from_response(response)
      xml = XML.new(response.body)

      location = xml.string("//CompleteMultipartUploadResult/Location")
      key = xml.string("//CompleteMultipartUploadResult/Key")
      etag = xml.string("//CompleteMultipartUploadResult/ETag")

      new(location, key, etag)
    end

    # The key of the uploaded object
    getter key

    # The full location of the uploaded object
    getter location

    # The etag of the uploaded object
    getter etag

    def initialize(@location : String, @key : String, @etag : String)
    end

    def_equals @key, @location, @etag
  end
end
