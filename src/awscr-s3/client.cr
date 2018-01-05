require "./responses/*"
require "./paginators/*"
require "uri"
require "xml/builder"

module Awscr::S3
  # An S3 client for interacting with S3.
  #
  # Creating an S3 Client
  #
  # ```
  # client = Client.new("region", "key", "secret")
  # ```
  #
  # Client with custom endpoint
  # ```
  # client = Client.new("region", "key", "secret", endpoint: "http://test.com")
  # ```
  #
  # Client with custom signer algorithm
  # ```
  # client = Client.new("region", "key", "secret", signer: :v2)
  # ```
  class Client
    @signer : Awscr::Signer::Signers::Interface

    def initialize(@region : String, @aws_access_key : String, @aws_secret_key : String, @endpoint : String? = nil, signer : Symbol = :v4)
      @signer = SignerFactory.get(
        version: signer,
        region: @region,
        aws_access_key: @aws_access_key,
        aws_secret_key: @aws_secret_key
      )
    end

    # List s3 buckets
    #
    # ```
    # client = Client.new("region", "key", "secret", signer: :v2)
    # resp = client.list_buckets
    # p resp.buckets.map(&.name) # => ["bucket1", "bucket2"]
    # ```
    def list_buckets
      resp = http.get("/")

      Response::ListAllMyBuckets.from_response(resp)
    end

    # Create a bucket, optionally place it in a region.
    #
    # ```
    # client = Client.new("region", "key", "secret")
    # resp = client.create_bucket("test")
    # p resp # => true
    # ```
    def put_bucket(bucket, region : String? = nil, headers : Hash(String, String) = Hash(String, String).new)
      body = if region
               ::XML.build do |xml|
                 xml.element("CreateBucketConfiguration") do
                   xml.element("LocationConstraint") do
                     xml.text(region.to_s)
                   end
                 end
               end
             end

      resp = http.put("/#{bucket}", body: body.to_s, headers: headers)

      resp.status_code == 200
    end

    # Start a multipart upload
    #
    # ```
    # client = Client.new("region", "key", "secret", signer: :v2)
    # resp = client.start_multipart_upload("bucket1", "obj")
    # p resp.upload_id # => someid
    # ```
    def start_multipart_upload(bucket : String, object : String,
                               headers : Hash(String, String) = Hash(String, String).new)
      resp = http.post("/#{bucket}/#{object}?uploads", headers: headers)

      Response::StartMultipartUpload.from_response(resp)
    end

    # Upload a part, for use in multipart uploading
    #
    # ```
    # client = Client.new("region", "key", "secret", signer: :v2)
    # resp = client.upload_part("bucket1", "obj", "someid", 123, "MY DATA")
    # p resp.upload_id # => someid
    # ```
    def upload_part(bucket : String, object : String,
                    upload_id : String, part_number : Int32, part : IO | String)
      resp = http.put("/#{bucket}/#{object}?partNumber=#{part_number}&uploadId=#{upload_id}", part)

      ouput = Response::UploadPartOutput.new(
        resp.headers["ETag"],
        part_number,
        upload_id
      )
    end

    # Complete a multipart upload
    #
    # ```
    # client = Client.new("region", "key", "secret", signer: :v2)
    # resp = client.complete_multipart_upload("bucket1", "obj", "123", parts)
    # p resp.key # => obj
    # ```
    def complete_multipart_upload(bucket : String, object : String, upload_id : String, parts : Array(Response::UploadPartOutput))
      body = ::XML.build do |xml|
        xml.element("CompleteMultipartUpload") do
          parts.each do |output|
            xml.element("Part") do
              xml.element("PartNumber") do
                xml.text(output.part_number.to_s)
              end

              xml.element("ETag") do
                xml.text(output.etag)
              end
            end
          end
        end
      end

      resp = http.post("/#{bucket}/#{object}?uploadId=#{upload_id}", body: body)
      Response::CompleteMultipartUpload.from_response(resp)
    end

    # Aborts a multi part upload. Returns true if the abort was a success, false
    # otherwise.
    #
    # ```
    # client = Client.new("region", "key", "secret", signer: :v2)
    # resp = client.abort_multipart_upload("bucket1", "obj", "123")
    # p resp # => true
    # ```
    def abort_multipart_upload(bucket : String, object : String, upload_id : String)
      resp = http.delete("/#{bucket}/#{object}?uploadId=#{upload_id}")

      resp.status_code == 204
    end

    # Get information about a bucket, useful for determining if a bucket exists.
    # Raises a `Http::ServerError` if the bucket does not exist.
    #
    # ```
    # client = Client.new("region", "key", "secret", signer: :v2)
    # resp = client.head_bucket("bucket1")
    # p resp # => true
    # ```
    def head_bucket(bucket)
      http.head("/#{bucket}")

      true
    end

    # Delete an object from a bucket, returns `true` if successful, `false`
    # otherwise.
    #
    # ```
    # client = Client.new("region", "key", "secret", signer: :v2)
    # resp = client.delete_object("bucket1", "obj")
    # p resp # => true
    # ```
    def delete_object(bucket, object, headers : Hash(String, String) = Hash(String, String).new)
      resp = http.delete("/#{bucket}/#{object}", headers)

      resp.status_code == 204
    end

    # Add an object to a bucket.
    #
    # ```
    # client = Client.new("region", "key", "secret", signer: :v2)
    # resp = client.put_object("bucket1", "obj", "MY DATA")
    # p resp.key # => "obj"
    # ```
    def put_object(bucket, object : String, body : IO | String,
                   headers : Hash(String, String) = Hash(String, String).new)
      resp = http.put("/#{bucket}/#{object}", body, headers)

      Response::PutObjectOutput.from_response(resp)
    end

    # Get the contents of an object in a bucket
    #
    # ```
    # client = Client.new("region", "key", "secret", signer: :v2)
    # resp = client.get_object("bucket1", "obj")
    # p resp.body # => "MY DATA"
    # ```
    def get_object(bucket, object : String)
      resp = http.get("/#{bucket}/#{object}")

      Response::GetObjectOutput.from_response(resp)
    end

    # List all the items in a bucket
    #
    # ```
    # client = Client.new("region", "key", "secret", signer: :v2)
    # resp = client.list_objects("bucket1", prefix: "test")
    # p resp.map(&.key) # => ["obj"]
    # ```
    def list_objects(bucket, max_keys = nil, prefix = nil)
      params = {
        "bucket"    => bucket,
        "list-type" => "2",
        "max-keys"  => max_keys.to_s,
        "prefix"    => prefix.to_s,
      }

      Paginator::ListObjectsV2.new(http, params)
    end

    # :nodoc:
    private def http
      Http.new(@signer, @region, @endpoint)
    end
  end
end
