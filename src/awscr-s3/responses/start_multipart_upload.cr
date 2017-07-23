require "xml"

module Awscr::S3::Response
  class StartMultipartUpload
    def self.from_response(response)
      xml = XML.new(response.body)

      bucket = xml.string("//InitiateMultipartUploadResult/Bucket")
      key = xml.string("//InitiateMultipartUploadResult/Key")
      upload_id = xml.string("//InitiateMultipartUploadResult/UploadId")

      new(bucket, key, upload_id)
    end

    getter key
    getter bucket
    getter upload_id

    def initialize(@bucket : String, @key : String, @upload_id : String)
    end

    def_equals @key, @bucket, @upload_id
  end
end
