require "xml"

module Awscr::S3::Response
  class ListAllMyBuckets
    def self.from_xml(xml)
      xml = XML.new(xml)

      buckets = [] of Bucket
      xml.array("ListAllMyBucketsResult/Buckets/Bucket") do |bucket|
        name = bucket.string("Name")
        creation_time = bucket.string("CreationDate")

        buckets << Bucket.new(name, creation_time)
      end

      new(buckets)
    end

    getter buckets

    def initialize(@buckets : Array(Bucket))
    end
  end
end
