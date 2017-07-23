require "xml"

module Awscr::S3::Response
  class GetObjectOutput
    getter body

    def initialize(@key : String, @body : IO | String)
    end
  end
end
