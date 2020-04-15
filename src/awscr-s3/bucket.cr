module Awscr::S3
  class Bucket
    # The name of the bucket
    getter name

    # The time the bucket was created
    getter creation_time

    # The owner of the bucket
    getter owner

    # An S3 Bucket
    def initialize(@name : String, @creation_time : Time, @owner : String? = nil)
    end

    # Compares the name of the bucket to other
    def ==(other : String)
      @name == other
    end

    def_equals @name, @creation_time
  end
end
