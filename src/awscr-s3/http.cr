require "./responses/*"
require "./paginators/*"
require "uri"

module Awscr::S3
  class Http
    def initialize(@signer : Awscr::Signer::Signers::Interface,
                   @region : String = standard_us_region,
                   @custom_endpoint : String? = nil)
      @endpoint = endpoint
    end

    @endpoint : URI
    @client : HTTP::Client?

    # Issue a DELETE request to the *path* with optional *headers*
    #
    # ```
    # http = Http.new(signer)
    # http.delete("/")
    # ```
    def delete(path, headers : Hash(String, String) = Hash(String, String).new)
      headers = HTTP::Headers.new.merge!(headers)
      exec("DELETE", path, headers: headers)
    end

    # Issue a POST request to the *path* with optional *headers*, and *body*
    #
    # ```
    # http = Http.new(signer)
    # http.post("/", body: IO::Memory.new("test"))
    # ```
    def post(path, body = nil, headers : Hash(String, String) = Hash(String, String).new)
      headers = HTTP::Headers.new.merge!(headers)
      exec("POST", path, headers: headers, body: body)
    end

    # Issue a PUT request to the *path* with optional *headers* and *body*
    #
    # ```
    # http = Http.new(signer)
    # http.put("/", body: IO::Memory.new("test"))
    # ```
    def put(path : String, body : IO | String | Bytes, headers : Hash(String, String) = Hash(String, String).new)
      headers = HTTP::Headers{"Content-Length" => body.size.to_s}.merge!(headers)
      exec("PUT", path, headers: headers, body: body)
    end

    # Issue a HEAD request to the *path*
    #
    # ```
    # http = Http.new(signer)
    # http.head("/")
    # ```
    def head(path, headers : Hash(String, String) = Hash(String, String).new)
      exec("HEAD", path, headers: HTTP::Headers.new.merge!(headers))
    end

    # Issue a GET request to the *path*
    #
    # ```
    # http = Http.new(signer)
    # http.get("/")
    # ```
    def get(path, headers : Hash(String, String) = Hash(String, String).new)
      exec("GET", path, headers: HTTP::Headers.new.merge!(headers))
    end

    # Issue a GET request to the *path*
    #
    # ```
    # http = Http.new(signer)
    # http.get("/") do |resp|
    #   pp resp
    # end
    # ```
    def get(path, headers : Hash(String, String) = Hash(String, String).new)
      exec("GET", path, headers: HTTP::Headers.new.merge!(headers)) do |resp|
        yield resp
      end
    end

    private def exec(method, path, headers, body = nil)
      retries = 0

      loop do
        resp = http.exec(method, path, headers, body)
        return handle_response!(resp)
      rescue ex : IO::Error
        raise ex if retries > 2
        @client = nil
        retries += 1
      end
    end

    private def exec(method, path, headers, body = nil, &)
      retries = 0

      loop do
        return http.exec(method, path, headers, body) do |resp|
          yield handle_response!(resp)
        end
      rescue ex : IO::Error
        raise ex if retries > 2
        @client = nil
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

    # :nodoc:
    private def endpoint : URI
      return URI.parse(@custom_endpoint.to_s) if @custom_endpoint
      return default_endpoint if @region == standard_us_region
      URI.parse("https://#{SERVICE_NAME}-#{@region}.amazonaws.com")
    end

    # :nodoc:
    private def standard_us_region
      "us-east-1"
    end

    # :nodoc:
    private def default_endpoint : URI
      URI.parse("https://#{SERVICE_NAME}.amazonaws.com")
    end

    # :nodoc:
    private def http
      @client ||= create_client(@endpoint, @signer)
    end

    private def create_client(endpoint, signer)
      HTTP::Client.new(endpoint).tap do |client|
        # When we are using V4 we must tell the signer to skip encoding the path
        # because we already did that
        if signer.is_a?(Awscr::Signer::Signers::V4)
          client.before_request do |request|
            signer.as(Awscr::Signer::Signers::V4).sign(request, encode_path: false)
          end
        else
          client.before_request { |request| signer.sign(request) }
        end
      end
    end
  end
end
