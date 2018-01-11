require "./content_type"

module Awscr::S3
  # Uploads a file to S3. If the file is 5MB it is uploaded in a single request.
  # If the file is greater than 5MB it is uploaded in parts.
  class FileUploader
    # :nodoc:
    UPLOAD_THRESHOLD = 5_000_000 # 5mb

    # Configurable options passed to a FileUploader instance
    struct Options
      # If true the uploader will automatically add a content type header
      getter with_content_types

      def initialize(@with_content_types : Bool)
      end
    end

    def initialize(@client : Client, @options : Options = Options.new(with_content_types: true))
    end

    # Upload a file to a bucket. Returns true if successful, otherwise an
    # `Http::ServerError` is thrown.
    #
    # ```
    # uploader = FileUpload.new(client)
    # uploader.upload("bucket1", "obj", IO::Memory.new("DATA!"))
    # ```
    def upload(bucket : String, object : String, io : IO, headers : Hash(String, String) = Hash(String, String).new)
      headers = @options.with_content_types ? headers.merge(content_type_header(io)) : headers

      if io.size < UPLOAD_THRESHOLD
        @client.put_object(bucket, object, io, headers)
      else
        uploader = MultipartFileUploader.new(@client)
        uploader.upload(bucket, object, io, headers)
      end
      true
    end

    def content_type_header(io : IO)
      {"Content-Type" => Awscr::S3::ContentType.get(io)}
    end
  end
end
