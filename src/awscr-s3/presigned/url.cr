module Awscr
  module S3
    module Presigned
      # A Presigned::URL, useful to share a link or create a link for a direct
      # PUT.
      class Url
        # Options for generating a `Presigned::Url`
        struct Options
          # The bucket for the presigned url
          getter bucket

          # The object key, it must start with '/'
          getter object

          # When the link expires, defaults to 1 day
          getter expires

          # Additional presigned options
          getter additional_options

          @expires : Int32
          @additional_options : Hash(String, String)
          @bucket : String
          @object : String

          def initialize(@object, @bucket, @expires = 86_400,
                         @additional_options = {} of String => String)
          end
        end

        def initialize(@region : String, @credentials : Signer::Credentials, @options : Options)
          @scope = Signer::Scope.new(@region, "s3", Time.now)
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
