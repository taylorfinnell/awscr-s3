module Awscr::S3
  class FileUploader
    UPLOAD_THRESHOLD = 5_000_000 # 5mb

    getter client

    def initialize(@client : Client)
    end

    def upload(bucket : String, object : String, io : IO, headers : Hash(String, String) = Hash(String, String).new)
      if io.size < UPLOAD_THRESHOLD
        client.put_object(bucket, object, io, headers)
      else
        uploader = MultipartFileUploader.new(client)
        uploader.upload(bucket, object, io, headers)
      end
    end
  end
end
