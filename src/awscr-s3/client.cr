require "./responses/*"
require "./paginators/*"
require "uri"

module Awscr::S3
  class Client
    def initialize(@region : String, @aws_access_key : String, @aws_secret_key : String)
      @http = Http.new(signer)
    end

    def list_buckets
      resp = @http.get("/")

      Response::ListAllMyBuckets.from_response(resp)
    end

    def head_bucket(bucket)
      @http.head("/#{bucket}")

      true
    end

    def delete_object(bucket, key)
      resp = @http.delete("/#{bucket}/#{key}")

      resp.status_code == 204
    end

    def put_object(bucket, key : String, io : IO | String)
      resp = @http.put("/#{bucket}/#{key}", io)

      Response::PutObjectOutput.from_response(resp)
    end

    def get_object(bucket, key : String)
      resp = @http.get("/#{bucket}/#{key}")

      Response::GetObjectOutput.from_response(resp)
    end

    def list_objects(bucket, max_keys = nil, prefix = nil, continuation_token = nil)
      params = {
        "bucket"             => bucket,
        "list-type"          => "2",
        "max-keys"           => max_keys.to_s,
        "prefix"             => prefix.to_s,
        "continuation-token" => continuation_token,
      }

      Paginator::ListObjectsV2.new(@http, params)
    end

    private def signer
      Awscr::Signer::Signers::V4.new(
        service: SERVICE_NAME,
        region: @region,
        aws_access_key: @aws_access_key,
        aws_secret_key: @aws_secret_key
      )
    end
  end
end
