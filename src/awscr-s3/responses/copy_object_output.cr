require "xml"

module Awscr::S3::Response
  class CopyObjectOutput
    # :nodoc:
    DATE_FORMAT = "%FT%T"

    # Create a `CopyObjectOutput` response from an
    # `HTTP::Client::Response` object
    def self.from_response(response)
      xml = XML.new(response.body)

      etag = xml.string("//CopyObjectResult/ETag").strip('"')
      last_modified = Time.parse(xml.string("//CopyObjectResult/LastModified"), DATE_FORMAT, Time::Location::UTC)

      new(etag, last_modified)
    end

    # The etag of the new object
    getter etag : String

    # Creation time of the object
    getter last_modified : Time

    def initialize(@etag, @last_modified)
    end

    def_equals @etag, @last_modified
  end
end
