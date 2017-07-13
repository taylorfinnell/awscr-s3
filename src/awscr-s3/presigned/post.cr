require "./post_policy"

module Awscr
  module S3
    module Presigned
      # Represents the URL and fields required to send a HTTP form POST to S3
      # for object uploading.
      class Post
        def initialize(@region : String, @aws_access_key : String, @aws_secret_key : String)
          @policy = Policy.new
        end

        # Build a post object by adding fields
        def build(&block)
          yield @policy

          time = Time.utc_now
          @policy.condition("x-amz-credential", credential_scope(time))
          @policy.condition("x-amz-algorithm", Signer::ALGORITHM)
          @policy.condition("x-amz-date", time.to_s("%Y%m%dT%H%M%SZ"))

          signer = Signer::Signers::V4.new("s3", @region,
                                           @aws_access_key, @aws_secret_key)
          signature = signer.sign(@policy.to_s)

          # Add the final fields
          @policy.condition("policy", @policy.to_s)
          @policy.condition("x-amz-signature", signature.to_s)
          self
        end

        # Returns if the post is valid, false otherwise
        def valid?
          !!(bucket && @policy.valid?)
        end

        # Return the url to post to
        def url
          raise Exception.new("Invalid URL, no bucket field") unless bucket
          "http://#{bucket}.s3.amazonaws.com"
        end

        # Returns the fields, without signature fields
        def fields
          @policy.fields
        end

        # :nodoc:
        private def credential_scope(time)
          [@aws_access_key, time.to_s("%Y%m%d"), @region, "s3", "aws4_request"].join("/")
        end

        # :nodoc:
        private def bucket
          if bucket = fields.find { |field| field.key == "bucket" }
            bucket.value
          end
        end
      end
    end
  end
end
