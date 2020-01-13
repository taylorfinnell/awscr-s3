require "xml"

module Awscr::S3::Response
  class GetObjectOutput
    # The body of the request object
    getter body
    # The headers returned along with the object response
    getter headers

    # Create a `GetObjectOutput` response from an
    # `HTTP::Client::Response` object
    def self.from_response(response)
      new(response.body, response.headers)
    end

    def initialize(@body : String, @headers : HTTP::Headers)
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
      new(response.body_io, response.headers)
    end

    def initialize(@body_io : IO, @headers : HTTP::Headers)
    end
  end
end
