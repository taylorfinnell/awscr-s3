require "xml"
require "uri"

module Awscr::S3::Response
  class ListObjectsV2
    # :nodoc:
    DATE_FORMAT = "%FT%T"

    # Create a `ListObjectsV2` response from an
    # `HTTP::Client::Response` object
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
        last_modified = Time.parse(object.string("LastModified"), DATE_FORMAT, Time::Location::UTC)

        objects << Object.new(key, size, etag, last_modified)
      end

      new(name, prefix, key_count.to_i? || 0, max_keys.to_i, truncated == "true", token, objects)
    end

    # The list of obects
    getter contents

    def initialize(@name : String, @prefix : String, @key_count : Int32,
                   @max_keys : Int32, @truncated : Bool, @continuation_token : String, @contents : Array(Object))
    end

    # The continuation token for the subsequent response, if any
    def next_token
      @continuation_token
    end

    # Returns true if the response is truncated, false otherwise
    def truncated?
      @truncated
    end

    def_equals @name, @prefix, @key_count, @max_keys, @truncated,
      @continuation_token, @contents
  end
end
