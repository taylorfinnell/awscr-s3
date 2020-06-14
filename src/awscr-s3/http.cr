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

    # Issue a DELETE request to the *path* with optional *headers*
    #
    # ```
    # http = Http.new(signer)
    # http.delete("/")
    # ```
    def delete(path, headers : Hash(String, String) = Hash(String, String).new)
      headers = HTTP::Headers.new.merge!(headers)
      resp = http.delete(path, headers: headers)
      handle_response!(resp)
    end

    # Issue a POST request to the *path* with optional *headers*, and *body*
    #
    # ```
    # http = Http.new(signer)
    # http.post("/", body: IO::Memory.new("test"))
    # ```
    def post(path, body = nil, headers : Hash(String, String) = Hash(String, String).new)
      headers = HTTP::Headers.new.merge!(headers)
      resp = http.post(path, headers: headers, body: body)
      handle_response!(resp)
    end

    # Issue a PUT request to the *path* with optional *headers* and *body*
    #
    # ```
    # http = Http.new(signer)
    # http.put("/", body: IO::Memory.new("test"))
    # ```
    def put(path : String, body : IO | String | Bytes, headers : Hash(String, String) = Hash(String, String).new)
      headers = HTTP::Headers{"Content-Length" => body.size.to_s}.merge!(headers)
      resp = http.put(path, headers: headers, body: body)
      handle_response!(resp)
    end

    # Issue a HEAD request to the *path*
    #
    # ```
    # http = Http.new(signer)
    # http.head("/")
    # ```
    def head(path, headers : Hash(String, String) = Hash(String, String).new)
      resp = http.head(path, headers: HTTP::Headers.new.merge!(headers))
      handle_response!(resp)
    end

    # Issue a GET request to the *path*
    #
    # ```
    # http = Http.new(signer)
    # http.get("/")
    # ```
    def get(path, headers : Hash(String, String) = Hash(String, String).new)
      resp = http.get(path, headers: HTTP::Headers.new.merge!(headers))
      handle_response!(resp)
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
      http.get(path, headers: HTTP::Headers.new.merge!(headers)) do |resp|
        handle_response!(resp)
        yield resp
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
      client = HTTP::Client.new(@endpoint)

      # When we are using V4 we must tell the signer to skip encoding the path
      # because we already did that
      if (signer = @signer).is_a?(Awscr::Signer::Signers::V4)
        client.before_request do |request|
          signer.as(Awscr::Signer::Signers::V4).sign(request, encode_path: false)
        end
      else
        client.before_request do |request|
          signer.sign(request)
        end
      end

      client
    end
  end
end
