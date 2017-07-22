module Awscr::S3
  class Object
    getter key
    getter size
    getter etag

    def initialize(@key : String, @size : Int32, @etag : String)
    end

    def_equals @key, @size, @etag
  end
end
