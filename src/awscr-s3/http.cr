require "./paginators/*"
require "uri"

module Awscr::S3
  class Http
    # Determines whether an `IO` is seekable (supports `#pos` and `#seek` without error)
    def self.seekable?(io : IO) : Bool
      return true if io.is_a?(IO::Memory)
      return false unless io.responds_to?(:pos) && io.responds_to?(:seek)
      begin
        io.pos
        true
      rescue
        false
      end
    end

    property max_retries : Int32

    def initialize(
      @signer : Awscr::Signer::Signers::Interface,
      @endpoint : URI,
      @factory : HttpClientFactory = DefaultHttpClientFactory.new,
      @max_retries : Int32 = 3,
    )
    end

    # Issue a DELETE request to the *path* with optional *headers*
    #
    # ```
    # http = Http.new(signer)
    # http.delete("/")
    # ```
    def delete(path, headers : Hash(String, String) = Hash(String, String).new, retries : Int32? = nil)
      headers = HTTP::Headers.new.merge!(headers)
      exec("DELETE", path, headers: headers, retries: retries)
    end

    # Issue a POST request to the *path* with optional *headers*, and *body*
    #
    # ```
    # http = Http.new(signer)
    # http.post("/", body: IO::Memory.new("test"))
    # ```
    def post(path, body = nil, headers : Hash(String, String) = Hash(String, String).new, retries : Int32? = nil)
      headers = HTTP::Headers.new.merge!(headers)
      exec("POST", path, headers: headers, body: body, retries: retries)
    end

    # Issue a PUT request to the *path* with optional *headers* and *body*
    #
    # ```
    # http = Http.new(signer)
    # http.put("/", body: IO::Memory.new("test"))
    # ```
    def put(path : String, body : IO | String | Bytes, headers : Hash(String, String) = Hash(String, String).new, retries : Int32? = nil)
      http_headers = HTTP::Headers.new.merge!(headers)
      unless http_headers.has_key?("Content-Length")
        if body.responds_to?(:size)
          http_headers["Content-Length"] = body.size.to_s
        end
      end

      if body.is_a?(IO) && !Http.seekable?(body)
        http_headers["X-Amz-Content-Sha256"] ||= "UNSIGNED-PAYLOAD"
      end

      exec("PUT", path, headers: http_headers, body: body, retries: retries)
    end

    # Issue a HEAD request to the *path*
    #
    # ```
    # http = Http.new(signer)
    # http.head("/")
    # ```
    def head(path, headers : Hash(String, String) = Hash(String, String).new, retries : Int32? = nil)
      exec("HEAD", path, headers: HTTP::Headers.new.merge!(headers), retries: retries)
    end

    # Issue a GET request to the *path*
    #
    # ```
    # http = Http.new(signer)
    # http.get("/")
    # ```
    def get(path, headers : Hash(String, String) = Hash(String, String).new, retries : Int32? = nil)
      exec("GET", path, headers: HTTP::Headers.new.merge!(headers), retries: retries)
    end

    # Issue a GET request to the *path*
    #
    # ```
    # http = Http.new(signer)
    # http.get("/") do |resp|
    #   pp resp
    # end
    # ```
    def get(path, headers : Hash(String, String) = Hash(String, String).new, retries : Int32? = nil, &)
      exec("GET", path, headers: HTTP::Headers.new.merge!(headers), retries: retries) do |resp|
        yield resp
      end
    end

    private def exec(method : String, path : String, headers, body = nil, retries : Int32? = nil)
      retries_attempted = 0
      effective_retries = retries || @max_retries

      loop do
        client = @factory.acquire_client(@endpoint, @signer)
        resp = client.exec(method, path, headers, body)
        return handle_response!(resp)
      rescue ex : IO::EOFError
        # Since Crystal 1.21.0, the HTTP client raises IO::EOFError when the connection is closed
        # (https://github.com/crystal-lang/crystal/pull/16981). Closing our client explicitly here,
        # forces the connection pool to create a new one.
        client.try &.close

        Awscr::S3::Log.debug exception: ex, &.emit("Could not process a request (connection closed)",
          retries: retries_attempted, method: method, path: path)
        raise ex if retries_attempted >= effective_retries
        prepare_body_for_retry!(body, ex)
        retries_attempted += 1
      rescue ex : IO::Error
        Awscr::S3::Log.debug exception: ex, &.emit("Could not process a request", retries: retries_attempted, method: method, path: path)
        raise ex if retries_attempted >= effective_retries
        prepare_body_for_retry!(body, ex)
        retries_attempted += 1
      ensure
        @factory.release(client)
      end
    end

    private def exec(method : String, path : String, headers, body = nil, retries : Int32? = nil, &)
      retries_attempted = 0
      effective_retries = retries || @max_retries

      loop do
        client = @factory.acquire_client(@endpoint, @signer)
        return client.exec(method, path, headers, body) do |resp|
          yield handle_response!(resp)
        end
      rescue ex : IO::EOFError
        client.try &.close

        Awscr::S3::Log.debug exception: ex, &.emit("Could not process a request (connection closed)",
          retries: retries_attempted, method: method, path: path)
        raise ex if retries_attempted >= effective_retries
        prepare_body_for_retry!(body, ex)
        retries_attempted += 1
      rescue ex : IO::Error
        Awscr::S3::Log.debug exception: ex, &.emit("Could not process a request", retries: retries_attempted, method: method, path: path)
        raise ex if retries_attempted >= effective_retries
        prepare_body_for_retry!(body, ex)
        retries_attempted += 1
      ensure
        @factory.release(client)
      end
    end

    private def prepare_body_for_retry!(body, original_exception)
      case body
      when IO
        if body.responds_to?(:rewind) && Http.seekable?(body)
          begin
            body.rewind
          rescue ex
            raise S3::Exception.new("Cannot retry request: body IO failed to rewind: #{ex.message}")
          end
        else
          raise S3::Exception.new("Cannot retry request: body IO cannot be rewound")
        end
      end
    end

    # :nodoc:
    private def handle_response!(response)
      return response if (200..299).includes?(response.status_code)

      if response.body_io? || !response.body?.try(&.empty?)
        raise S3::Exception.from_response(response)
      else
        raise S3::Exception.new("server error: #{response.status_code}")
      end
    end
  end
end
