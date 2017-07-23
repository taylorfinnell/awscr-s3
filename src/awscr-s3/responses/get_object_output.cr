require "xml"

module Awscr::S3::Response
  class GetObjectOutput
    getter body

    def self.from_response(response)
      new(response.body)
    end

    def initialize(@body : IO | String)
    end

    def_equals @body
  end
end
