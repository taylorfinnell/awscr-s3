module Awscr
  module S3
    class SignerFactory
      def self.get(region : String, aws_access_key : String,
                   aws_secret_key : String, version : Symbol)
        case version
        when :v4
          Awscr::Signer::Signers::V4.new(
            service: "s3",
            region: region,
            aws_access_key: aws_access_key,
            aws_secret_key: aws_secret_key
          )
        when :v2
          Awscr::Signer::Signers::V2.new(
            service: "s3",
            region: region,
            aws_access_key: aws_access_key,
            aws_secret_key: aws_secret_key
          )
        else
          raise "Unknown signer version: #{version}"
        end
      end
    end
  end
end
