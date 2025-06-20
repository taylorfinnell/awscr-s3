require "xml"

module Awscr::S3::Response
  class PutObjectOutput < Base
    # Create a `PutObjectOutput` response from an
    # `HTTP::Client::Response` object
    def self.from_response(response)
      new(response.headers["ETag"], response.status, response.status_message, response.headers)
    end

    # The etag of the new object
    getter etag

    def initialize(
      @etag : String,
      @status : HTTP::Status,
      @status_message : String? = nil,
      @headers : HTTP::Headers = HTTP::Headers.new,
    )
    end

    def_equals @etag
  end
end
