module Awscr::S3
  # Uploads a file to S3. If the file is 5MB it is uploaded in a single request.
  # If the file is greater than 5MB it is uploaded in parts.
  class FileUploader
    # :nodoc:
    UPLOAD_THRESHOLD = 5_000_000 # 5mb

    def initialize(@client : Client)
    end

    # Upload a file to a bucket
    #
    # ```
    # uploader = FileUpload.new(client)
    # uploader.upload("bucket1", "obj", "DATA!")
    # ```
    def upload(bucket : String, object : String, io : IO, headers : Hash(String, String) = Hash(String, String).new)
      if io.size < UPLOAD_THRESHOLD
        @client.put_object(bucket, object, io, headers)
      else
        uploader = MultipartFileUploader.new(@client)
        uploader.upload(bucket, object, io, headers)
      end
    end
  end
end
