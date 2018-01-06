require "xml"
require "uri"

module Awscr::S3::Response
  class ListObjectsV2
    def self.from_response(response)
      xml = XML.new(response.body)

      name = xml.string("//ListBucketResult/Name")
      prefix = xml.string("//ListBucketResult/Prefix")
      key_count = xml.string("//ListBucketResult/KeyCount")
      max_keys = xml.string("//ListBucketResult/MaxKeys")
      truncated = xml.string("//ListBucketResult/IsTruncated")
      token = xml.string("//ListBucketResult/NextContinuationToken")

      objects = [] of Object
      xml.array("ListBucketResult/Contents") do |object|
        key = object.string("Key")
        size = object.string("Size").to_i
        etag = object.string("ETag")

        objects << Object.new(key, size, etag)
      end

      new(name, prefix, key_count.to_i, max_keys.to_i, truncated == "true", token, objects)
    end

    getter contents

    def initialize(@name : String, @prefix : String, @key_count : Int32,
                   @max_keys : Int32, @truncated : Bool, @continuation_token : String, @contents : Array(Object))
    end

    def next_token
      @continuation_token
    end

    def truncated?
      @truncated
    end

    def_equals @name, @prefix, @key_count, @max_keys, @truncated,
      @continuation_token, @contents
  end
end
