require "./responses/*"
require "./paginators/*"
require "uri"

module Awscr::S3
  class Http
    class ServerError < Exception
      def self.from_response(response)
        xml = XML.new(response.body)

        code = xml.string("//Error/Code")
        message = xml.string("//Error/Message")

        new("#{code}: #{message}")
      end
    end

    def initialize(@signer : Awscr::Signer::Signers::Interface,
                   @region : String = standard_us_region,
                   @custom_endpoint : String? = nil)
      @http = HTTP::Client.new(endpoint)

      @http.before_request do |request|
        @signer.sign(request)
      end
    end

    def delete(path, headers : Hash(String, String) = Hash(String, String).new)
      headers = HTTP::Headers.new.merge!(headers)
      resp = @http.delete(path, headers: headers)
      handle_response!(resp)
    end

    def post(path, body = nil, headers : Hash(String, String) = Hash(String, String).new)
      headers = HTTP::Headers.new.merge!(headers)
      resp = @http.post(path, headers: headers, body: body)
      handle_response!(resp)
    end

    def put(path : String, body : IO | String, headers : Hash(String, String) = Hash(String, String).new)
      headers = HTTP::Headers{"Content-Length" => body.size.to_s}.merge!(headers)
      resp = @http.put(path, headers: headers, body: body)
      handle_response!(resp)
    end

    def head(path)
      resp = @http.head(path)
      handle_response!(resp)
    end

    def get(path)
      resp = @http.get(path)
      handle_response!(resp)
    end

    private def handle_response!(response)
      return response if (200..299).includes?(response.status_code)

      if !response.body.empty?
        raise ServerError.from_response(response)
      else
        raise ServerError.new("server error: #{response.status_code}")
      end
    end

    private def endpoint : URI
      return URI.parse(@custom_endpoint.to_s) if @custom_endpoint
      return default_endpoint if @region == standard_us_region
      URI.parse("http://#{SERVICE_NAME}-#{@region}.amazonaws.com")
    end

    private def standard_us_region
      "us-east-1"
    end

    private def default_endpoint : URI
      URI.parse("http://#{SERVICE_NAME}.amazonaws.com")
    end
  end
end
