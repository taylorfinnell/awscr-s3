require "xml"

module Awscr::S3::Response
  class CompleteMultipartUpload
    def self.from_response(response)
      xml = XML.new(response.body)

      location = xml.string("//CompleteMultipartUploadResult/Location")
      key = xml.string("//CompleteMultipartUploadResult/Key")
      etag = xml.string("//CompleteMultipartUploadResult/ETag")

      new(location, key, etag)
    end

    getter key
    getter location
    getter etag

    def initialize(@location : String, @key : String, @etag : String)
    end

    def_equals @key, @location, @etag
  end
end
