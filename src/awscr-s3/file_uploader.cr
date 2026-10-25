require "./content_type"

module Awscr::S3
  # Uploads a file to S3. If the file is smaller than 5MB it is uploaded in a single request.
  # If the file is 5MB or greater, or if size is unknown, it is uploaded in parts.
  class FileUploader
    # :nodoc:
    UPLOAD_THRESHOLD = (5 * 1024 * 1024).to_i64 # 5MB

    # Configurable options passed to a FileUploader instance
    struct Options
      # If true the uploader will automatically add a content type header
      getter with_content_types
      getter simultaneous_parts
      getter minimum_part_size
      getter multipart_threshold
      getter retries

      def initialize(
        @with_content_types : Bool,
        @simultaneous_parts : Int32 = 5,
        @minimum_part_size : Int64 = MultipartFileUploader::MIN_PART_SIZE,
        @multipart_threshold : Int64 = UPLOAD_THRESHOLD,
        @retries : Int32? = nil,
      )
      end
    end

    def initialize(@client : Client, @options : Options = Options.new(with_content_types: true))
    end

    # Upload a file to a bucket. Returns true if successful, otherwise an
    # exception is thrown.
    #
    # ```
    # uploader = FileUploader.new(client)
    # uploader.upload("bucket1", "obj", IO::Memory.new("DATA!"))
    # ```
    def upload(bucket : String, object : String, io : IO, headers : Hash(String, String) = Hash(String, String).new, retries : Int32? = nil)
      headers = @options.with_content_types ? headers.merge(content_type_header(io)) : headers
      effective_retries = retries || @options.retries

      content_length = if headers.has_key?("Content-Length")
                         headers["Content-Length"].to_i64?
                       elsif io.responds_to?(:size)
                         begin
                           io.size.to_i64
                         rescue
                           nil
                         end
                       end

      if content_length && content_length < @options.multipart_threshold
        @client.put_object(bucket, object, io, headers, retries: effective_retries)
      else
        uploader = MultipartFileUploader.new(
          @client,
          @options.simultaneous_parts,
          @options.minimum_part_size,
          retries: effective_retries
        )
        uploader.upload(bucket, object, io, headers)
      end
      true
    end

    def content_type_header(io : IO)
      {"Content-Type" => Awscr::S3::ContentType.get(io)}
    end
  end
end
