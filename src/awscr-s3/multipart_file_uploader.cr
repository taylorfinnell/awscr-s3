module Awscr::S3
  # :nodoc:
  class MultipartFileUploader
    MIN_PART_SIZE = (5 * 1024 * 1024).to_i64 # 5MB

    getter client

    @upload_id : String?
    @bucket : String?
    @object : String?
    @headers : Hash(String, String)?
    @error : ::Exception?
    @mutex : Mutex
    @completed : Channel(Nil)
    @retries : Int32?

    def initialize(
      @client : Client,
      @simultaneous : Int32 = 5,
      @minimum_part_size : Int64 = MIN_PART_SIZE,
      @retries : Int32? = nil,
    )
      @parts = [] of Response::UploadPartOutput
      @completed = Channel(Nil).new
      @mutex = Mutex.new
      @error = nil
    end

    # Uploads an *object* to a *bucket*, in multiple parts
    def upload(bucket : String, object : String, io : IO, headers : Hash(String, String) = Hash(String, String).new)
      @bucket = bucket
      @object = object
      @headers = headers
      @parts.clear
      @error = nil
      @upload_id = start_upload

      part_size = compute_part_size(io)
      upload_stream(io, part_size)
      complete_upload
    end

    private def compute_part_size(io) : Int64
      if io.responds_to?(:size)
        begin
          [(io.size.to_i64 // 10_000).ceil, @minimum_part_size].max
        rescue
          @minimum_part_size
        end
      else
        @minimum_part_size
      end
    end

    private def upload_stream(io, part_size)
      buffer_pool = Channel(Bytes).new(@simultaneous)
      @simultaneous.times { buffer_pool.send(Bytes.new(part_size)) }

      in_flight = 0
      part_number = 1

      while @error.nil?
        buffer = buffer_pool.receive
        bytes_read = 0
        while bytes_read < part_size
          read = io.read(buffer[bytes_read..-1])
          break if read == 0
          bytes_read += read
        end

        if bytes_read == 0 && part_number > 1
          buffer_pool.send(buffer)
          break
        end

        chunk = buffer[0, bytes_read]
        current_part = part_number
        part_number += 1
        in_flight += 1

        spawn upload_single_part(buffer_pool, buffer, chunk, current_part)

        break if bytes_read < part_size
      end

      in_flight.times { @completed.receive }

      if err = @error
        begin
          client.abort_multipart_upload(bucket, object, upload_id)
        rescue
        end
        raise err
      end
    end

    private def upload_single_part(buffer_pool, buffer, chunk, current_part)
      part_io = IO::Memory.new(chunk, writable: false)
      resp = client.upload_part(
        bucket,
        object,
        upload_id,
        current_part,
        part_io,
        headers: {"X-Amz-Content-Sha256" => "UNSIGNED-PAYLOAD"},
        retries: @retries
      )
      @mutex.synchronize { @parts << resp }
    rescue ex
      @mutex.synchronize { @error ||= ex }
    ensure
      buffer_pool.send(buffer)
      @completed.send(nil)
    end

    private def complete_upload
      client.complete_multipart_upload(
        bucket,
        object,
        upload_id,
        @parts.sort_by(&.part_number),
        retries: @retries
      )
    end

    private def start_upload
      resp = client.start_multipart_upload(bucket, object, headers, retries: @retries)
      resp.upload_id
    end

    private def upload_id
      @upload_id.not_nil!
    end

    private def bucket
      @bucket.not_nil!
    end

    private def object
      @object.not_nil!
    end

    private def headers
      @headers.not_nil!
    end
  end
end
