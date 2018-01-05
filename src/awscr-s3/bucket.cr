module Awscr::S3
  class Bucket
    # An S3 Bucket
    def initialize(@name : String, @creation_time : Time)
    end

    def_equals @name, @creation_time
  end
end
