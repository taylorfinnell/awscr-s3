require "xml"

module Awscr::S3::Response
  class ListAllMyBuckets
    include Enumerable(Bucket)

    # :nodoc:
    DATE_FORMAT = "%Y-%M-%dT%H:%M:%S.%z"

    def self.from_response(response)
      xml = XML.new(response.body)

      owner = xml.string("ListAllMyBucketsResult/Owner/DisplayName")

      buckets = [] of Bucket
      xml.array("ListAllMyBucketsResult/Buckets/Bucket") do |bucket|
        name = bucket.string("Name")
        creation_time = bucket.string("CreationDate")

        buckets << Bucket.new(name, Time.parse(creation_time, DATE_FORMAT),
          owner)
      end

      new(buckets)
    end

    getter buckets

    def initialize(@buckets : Array(Bucket))
    end

    def each(&block)
      @buckets.each { |b| yield b }
    end

    def_equals @buckets
  end
end
