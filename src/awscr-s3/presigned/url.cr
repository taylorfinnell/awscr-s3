require "../log"
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
        @scheme : String

        def initialize(@options : Options)
          @aws_access_key = @options.aws_access_key
          @aws_secret_key = @options.aws_secret_key
          @region = @options.region
          @scheme = @options.scheme
        end

        # Create a Presigned::Url link. Supports GET and PUT.
        def for(method : Symbol)
          raise S3::Exception.new("unsupported method #{method}") unless allowed_methods.includes?(method)

          request = build_request(method.to_s.upcase)

          @options.additional_options.each do |k, v|
            request.query_params.add(k, v)
          end

          presign_request(request)

          String.build do |str|
            str << "#{@scheme}://"
            str << request.headers["Host"]

            if @options.include_port
              if header = request.headers["Host"]?
                if header.includes?(":")
                  _, _, port = header.rpartition(":")
                  unless port == ""
                    str << ":"
                    str << port
                  end
                end
              end
            end

            str << request.resource
          end
        end

        # :nodoc:
        private def presign_request(request)
          # https://opentelemetry.io/docs/specs/semconv/
          Log.trace &.emit("Presign request", {
            "code.filepath":       __FILE__,
            "code.function.name":  "presign_request",
            "code.line.number":    __LINE__,
            "code.location":       "#{__FILE__}:#{__LINE__}",
            "http.request.method": request.method,
            "server.address":      request.headers["Host"],
            "url.path":            request.path,
            "url.query":           request.query,
          })
          @options.signer.presign(request)
        end

        # :nodoc:
        private def build_request(method)
          headers = HTTP::Headers{"Host" => host}

          body = @options.signer_version == :v4 ? "UNSIGNED-PAYLOAD" : nil

          key = @options.object.starts_with?("/") ? @options.object : "/#{@options.object}"

          path = if @options.force_path_style?
                   "/#{@options.bucket}#{key}"
                 else
                   key
                 end

          request = HTTP::Request.new(
            method,
            path,
            headers,
            body
          )

          if @options.signer_version == :v4
            request.query_params.add("X-Amz-Expires", @options.expires.to_s)
          else
            request.query_params.add("Expires", (Time.utc.to_unix + @options.expires).to_s)
          end

          request
        end

        # :nodoc:
        private def host
          host_name = base_host
          @options.force_path_style? ? host_name : "#{@options.bucket}.#{host_name}"
        end

        def base_host
          if host_name = @options.host_name
            return host_name
          end
          return default_host if @region == standard_us_region
          "s3-#{@region}.amazonaws.com"
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
