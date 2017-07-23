require "xml"

module Awscr::S3::Response
  class PutObjectOutput
    def initialize(@key : String, @etag : String)
    end
  end
end
