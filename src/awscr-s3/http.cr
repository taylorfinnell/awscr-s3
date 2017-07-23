require "./responses/*"
require "./paginators/*"
require "uri"

module Awscr::S3
  class Http
    class ServerError < Exception
    end

    def initialize(@signer : Awscr::Signer::Signers::V4)
      @http = HTTP::Client.new("#{SERVICE_NAME}.amazonaws.com")

      @http.before_request do |request|
        @signer.sign(request)
      end
    end

    def put(path, body)
      resp = @http.put(path, body: body)
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
        raise ServerError.new(response.body)
      else
        raise ServerError.new("server error: #{response.status_code}")
      end
    end
  end
end
