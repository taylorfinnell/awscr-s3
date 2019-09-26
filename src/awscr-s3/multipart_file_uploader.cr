module Awscr::S3
  # :nodoc:
  private class Part
    getter offset
    getter size
    getter number

    def initialize(@offset : Int32, @size : Int32, @number : Int32)
    end
  end

  # :nodoc:
  private class MultipartFileUploader
    getter client

    @upload_id : String?
    @bucket : String?
    @object : String?
    @headers : Hash(String, String)?

    def initialize(@client : Client)
      @pending = [] of Part
      @parts = [] of Response::UploadPartOutput
      @channel = Channel(Nil).new
    end

    # Uploads an *object* to a *bucket*, in multiple parts
    def upload(bucket : String, object : String, io : IO, headers : Hash(String, String) = Hash(String, String).new)
      @bucket = bucket
      @object = object
      @headers = headers
      @upload_id = start_upload

      build_pending_parts(io)
      upload_pending(io)
      complete_upload
    end

    private def build_pending_parts(io)
      offset = 0
      size = io.size
      default_part_size = compute_default_part_size(io.size)
      number = 1

      loop do
        @pending << Part.new(
          offset: offset,
          size: part_size(size, default_part_size, offset).to_i32,
          number: number
        )

        offset += default_part_size

        number += 1

        break if offset >= size
      end
    end

    private def compute_default_part_size(source_size)
      [(source_size // 10_000).ceil, 5 * 1024 * 1024].max
    end

    private def part_size(total_size, part_size, offset)
      if offset + part_size > total_size
        total_size - offset
      else
        part_size
      end
    end

    private def upload_pending(io)
      @pending.each do |part|
        bytes = Bytes.new(part.size)

        io.skip(part.offset)
        io.read(bytes)
        io.rewind

        spawn upload_part(bytes, part)
      end

      @pending.size.times { @channel.receive }
    end

    private def upload_part(bytes, part)
      @parts << client.upload_part(
        bucket,
        object,
        upload_id,
        part.number,
        IO::Memory.new(bytes)
      )
    ensure
      @channel.send(nil)
    end

    private def complete_upload
      client.complete_multipart_upload(
        bucket,
        object,
        upload_id,
        @parts.sort_by(&.part_number)
      )
    end

    private def start_upload
      resp = client.start_multipart_upload(bucket, object, headers)
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
