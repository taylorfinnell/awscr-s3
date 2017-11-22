require "./url_options"

module Awscr
  module S3
    module Presigned
      # A Presigned::URL, useful to share a link or create a link for a direct
      # PUT.
      class Url
        @aws_access_key : String
        @aws_secret_key : String
        @region : String

        def initialize(@options : Options)
          @aws_access_key = @options.aws_access_key
          @aws_secret_key = @options.aws_secret_key
          @region = @options.region
        end

        # Create a Presigned::Url link. Supports GET and PUT.
        def for(method : Symbol)
          raise "unsupported method #{method}" unless allowed_methods.includes?(method)

          request = build_request(method.to_s.upcase)

          @options.additional_options.each do |k, v|
            request.query_params.add(k, v)
          end

          presign_request(request)

          String.build do |str|
            str << "https://"
            str << request.host
            str << request.resource
          end
        end

        # :nodoc:
        private def presign_request(request)
          signer = Signer::Signers::V4.new(
            SERVICE_NAME,
            @region,
            @aws_access_key,
            @aws_secret_key
          )
          signer.presign(request)
        end

        # :nodoc:
        private def build_request(method)
          headers = HTTP::Headers{"Host" => host}

          request = HTTP::Request.new(
            method,
            "/#{@options.bucket}#{@options.object}",
            headers,
            "UNSIGNED-PAYLOAD"
          )

          request.query_params.add("X-Amz-Expires", @options.expires.to_s)
          request
        end

        # :nodoc:
        private def host
          if host_name = @options.host_name
            host_name
          else
            return default_host if @region == standard_us_region
            "s3-#{@region}.amazonaws.com"
          end
        end

        # :nodoc:
        private def standard_us_region
          "us-east-1"
        end

        # :nodoc:
        private def default_host
          "s3.amazonaws.com"
        end

        # :nodoc:
        private def allowed_methods
          [:get, :put]
        end
      end
    end
  end
end
