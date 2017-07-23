require "xml"

module Awscr::S3::Response
  class UploadPartOutput
    getter etag
    getter part_number
    getter upload_id

    def initialize(@etag : String, @part_number : Int32, @upload_id : String)
    end

    def_equals @etag, @part_number, @upload_id
  end
end
