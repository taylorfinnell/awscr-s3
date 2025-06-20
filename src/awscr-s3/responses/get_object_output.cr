require "xml"

module Awscr::S3::Response
  class GetObjectOutput < Base
    # The body of the request object
    getter body
    # The headers returned along with the object response
    getter headers

    # Create a `GetObjectOutput` response from an
    # `HTTP::Client::Response` object
    def self.from_response(response)
      new(response.body, response.status, response.status_message, response.headers)
    end

    def initialize(
      @body : String,
      @status : HTTP::Status,
      @status_message : String? = nil,
      @headers : HTTP::Headers = HTTP::Headers.new,
    )
    end
  end

  class GetObjectStream
    # Body IO for streaming the body of the object
    getter body_io

    # The headers returned along with the object response
    getter headers

    # Create a `GetObjectStream` response from an
    # `HTTP::Client::Response` object
    def self.from_response(response)
      new(response.body_io, response.status, response.status_message, response.headers)
    end

    def initialize(
      @body_io : IO,
      @status : HTTP::Status,
      @status_message : String? = nil,
      @headers : HTTP::Headers = HTTP::Headers.new,
    )
    end
  end
end
