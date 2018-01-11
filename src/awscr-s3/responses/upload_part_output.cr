require "xml"

module Awscr::S3::Response
  class UploadPartOutput
    # The etag of the uploaded part
    getter etag

    # The part number
    getter part_number

    # The upload id for the uploaded part
    getter upload_id

    def initialize(@etag : String, @part_number : Int32, @upload_id : String)
    end

    def_equals @etag, @part_number, @upload_id
  end
end
