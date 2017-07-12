require "./post_policy"

module Awscr
  module S3
    module Presigned
      # Represents the URL and fields required to send a HTTP form POST to S3
      # for object uploading.
      class Post
        def initialize(region : String, aws_access_key : String,
                       aws_secret_key : String, time : Time = Time.utc_now)
          @scope = Signer::Scope.new(region, "s3", time)
          @policy = Policy.new
          @credentials = Signer::Credentials.new(aws_access_key, aws_access_key)
        end

        # Build a post object by adding fields
        def build(&block)
          yield @policy

          @policy.condition("x-amz-credential", "#{@credentials.key}/#{@scope.to_s}")
          @policy.condition("x-amz-algorithm", Signer::ALGORITHM)
          @policy.condition("x-amz-date", @scope.date.iso8601)

          signer = Signer::Signers::V4.new(@scope, @credentials)
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
        private def bucket
          if bucket = fields.find { |field| field.key == "bucket" }
            bucket.value
          end
        end
      end
    end
  end
end
