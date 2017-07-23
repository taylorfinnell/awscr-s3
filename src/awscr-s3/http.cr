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

    def initialize(@signer : Awscr::Signer::Signers::V4)
      @http = HTTP::Client.new("#{SERVICE_NAME}.amazonaws.com")

      @http.before_request do |request|
        @signer.sign(request)
      end
    end

    def delete(path)
      resp = @http.delete(path)
      handle_response!(resp)
      resp
    end

    def post(path, body = nil)
      resp = @http.post(path, body: body)
      handle_response!(resp)
      resp
    end

    def put(path : String, body : IO | String)
      resp = @http.put(path, headers: HTTP::Headers{"Content-Length" => body.size.to_s}, body: body)
      handle_response!(resp)
      resp
    end

    def head(path)
      resp = @http.head(path)
      handle_response!(resp)
      resp
    end

    def get(path)
      resp = @http.get(path)
      handle_response!(resp)
      resp
    end

    private def handle_response!(response)
      # return true if the response is fine
      return true if (200..299).includes?(response.status_code)

      # ok the server said what is wrong, if there is a body in the response we
      # can get a specific message, otherwise we reraise a server error
      if !response.body.empty?
        raise ServerError.from_response(response)
      else
        raise ServerError.new("server error: #{response.status_code}")
      end
    end
  end
end
