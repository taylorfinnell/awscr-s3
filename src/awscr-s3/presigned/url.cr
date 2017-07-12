require "./url_options"

module Awscr
  module S3
    module Presigned
      # A Presigned::URL, useful to share a link or create a link for a direct
      # PUT.
      class Url
        def initialize(@options : Options)
          @scope = Signer::Scope.new(@options.region, "s3")

          @credentials = Signer::Credentials.new(
            @options.aws_access_key,
            @options.aws_secret_key
          )
        end

        # Create a Presigned::Url link.
        def for(method : Symbol)
          raise "unsupported method #{method}" unless allowed_methods.includes?(method)

          headers = HTTP::Headers.new
          headers.add("Host", "s3.amazonaws.com")

          request = HTTP::Request.new(method.to_s.upcase,
            "/#{@options.bucket}#{@options.object}",
            headers,
            "UNSIGNED-PAYLOAD")

          request.query_params.add("X-Amz-Expires", @options.expires.to_s)

          @options.additional_options.each do |k, v|
            request.query_params.add(k, v)
          end

          signer = Signer::Signers::V4.new(@scope, @credentials)
          signer.presign(request)

          String.build do |str|
            str << "https://"
            str << request.host
            str << request.resource
          end
        end

        # :nodoc:
        private def allowed_methods
          [:get, :put]
        end
      end
    end
  end
end
