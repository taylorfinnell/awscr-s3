module Awscr::S3
  class Bucket
    getter name, creation_time

    # An S3 Bucket
    def initialize(@name : String, @creation_time : Time)
    end

    def_equals @name, @creation_time
  end
end
