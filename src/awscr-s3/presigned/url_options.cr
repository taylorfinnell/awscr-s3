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

          @expires : Int32
          @additional_options : Hash(String, String)
          @bucket : String
          @object : String
          @region : String
          @aws_access_key : String
          @aws_secret_key : String
          @host_name : String?

          def initialize(@aws_access_key, @aws_secret_key, @region,
                         @object, @bucket, @expires = 86_400, @host_name = nil,
                         @additional_options = {} of String => String, @signer = :v4)
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
