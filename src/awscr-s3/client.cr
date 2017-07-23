require "./responses/*"
require "./paginators/*"
require "uri"
require "xml/builder"

module Awscr::S3
  class Client
    def initialize(@region : String, @aws_access_key : String, @aws_secret_key : String)
      @http = Http.new(signer)
    end

    def list_buckets
      resp = @http.get("/")

      Response::ListAllMyBuckets.from_response(resp)
    end

    def start_multipart_upload(bucket : String, object : String)
      resp = @http.post("/#{bucket}/#{object}?uploads")

      Response::StartMultipartUpload.from_response(resp)
    end

    def upload_part(bucket : String, object : String,
                    upload_id : String, part_number : Int32, part : IO | String)
      resp = @http.put("/#{bucket}/#{object}?partNumber=#{part_number}&uploadId=#{upload_id}", part)

      ouput = Response::UploadPartOutput.new(
        resp.headers["ETag"],
        part_number,
        upload_id
      )
    end

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

      resp = @http.post("/#{bucket}/#{object}?uploadId=#{upload_id}", body: body)
      Response::CompleteMultipartUpload.from_response(resp)
    end

    def abort_multipart_upload(bucket : String, object : String, upload_id : String)
      resp = @http.delete("/#{bucket}/#{object}?uploadId=#{upload_id}")

      resp.status_code == 204
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
