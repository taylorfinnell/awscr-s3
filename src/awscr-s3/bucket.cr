module Awscr::S3
  class Bucket
    getter name, creation_time, owner

    # An S3 Bucket
    def initialize(@name : String, @creation_time : Time, @owner : String? = nil)
    end

    def_equals @name, @creation_time
  end
end
