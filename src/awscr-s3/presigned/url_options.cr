module Awscr
  module S3
    module Presigned
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

          # Aws access key
          getter aws_access_key

          # Aws secret key
          getter aws_secret_key

          # The Aws region
          getter region

          # Optionally set the host name to use. The default is s3.amazonaws.com
          getter host_name

          # Optionally include the port in the presigned url
          getter include_port

          # The scheme attached to the given host. ie: <scheme>://<host_name>. Default: https
          getter scheme

          # Use path format for bucket specification <scheme>://<host_name>/<bucket>/<key> <scheme>://<bucket>.<host_name>/<key>
          getter? force_path_style : Bool = false

          @expires : Int32
          @additional_options : Hash(String, String)
          @bucket : String
          @object : String
          @region : String
          @aws_access_key : String
          @aws_secret_key : String
          @host_name : String?
          @include_port : Bool

          def initialize(@aws_access_key, @aws_secret_key, @region, @object, @bucket,
                         endpoint = nil,
                         @expires = 86_400,
                         @host_name = nil,
                         @additional_options = Hash(String, String).new,
                         @signer = :v4,
                         @include_port = false,
                         @force_path_style = false,
                         @scheme = "https")
            if endpoint
              uri = URI.parse(endpoint)
              scheme = uri.scheme
              @scheme = scheme if scheme
              host_name = uri.host
              if host_name
                if uri.port && uri.port != URI.default_port(@scheme)
                  host_name += ":#{uri.port}"
                end
                @host_name = host_name
              end
            end
          end

          def signer_version
            @signer
          end

          def signer
            SignerFactory.get(
              version: @signer,
              region: @region,
              aws_access_key: @aws_access_key,
              aws_secret_key: @aws_secret_key
            )
          end
        end
      end
    end
  end
end
