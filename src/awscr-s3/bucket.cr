module Awscr::S3
  class Bucket
    def initialize(@name : String, @creation_time : String)
    end

    def_equals @name, @creation_time
  end
end
