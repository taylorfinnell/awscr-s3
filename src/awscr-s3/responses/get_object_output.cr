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
      new(response.body? || response.body_io, response.headers)
    end

    def initialize(@body : IO | String, @headers : HTTP::Headers)
    end

    def_equals @body
  end
end
