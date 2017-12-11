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

    def initialize(@signer : Awscr::Signer::Signers::V4,
                   @region : String = standard_us_region)
      @http = HTTP::Client.new(host)

      @http.before_request do |request|
        @signer.sign(request)
      end
    end

    def delete(path)
      resp = @http.delete(path)
      handle_response!(resp)
    end

    def post(path, body = nil)
      resp = @http.post(path, body: body)
      handle_response!(resp)
    end

    def put(path : String, body : IO | String)
      resp = @http.put(path, headers: HTTP::Headers{"Content-Length" => body.size.to_s}, body: body)
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

    private def host
      return default_host if @region == standard_us_region
      "#{SERVICE_NAME}-#{@region}.amazonaws.com"
    end

    private def standard_us_region
      "us-east-1"
    end

    private def default_host
      "#{SERVICE_NAME}.amazonaws.com"
    end
  end
end
