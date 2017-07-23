require "xml"

module Awscr::S3::Response
  class PutObjectOutput
    def self.from_response(response)
      new(response.headers["ETag"])
    end

    def initialize(@etag : String)
    end

    def_equals @etag
  end
end
