module Awscr::S3
  class Presigner
    def initialize(client : Client)
      @aws_access_key = client.aws_access_key
      @aws_secret_key = client.aws_secret_key
      @endpoint = client.endpoint
      @region = client.region
    end

    def presigned_url(
      bucket : String,
      key : String,
      method : Symbol = :get,
      expires : Int32 = 86_400,
      include_port : Bool = false,
      force_path_style : Bool = false,
      signer : Symbol = :v4,
      **kwargs,
    )
      opts = hash = {} of String => String
      kwargs.each { |k, v| hash[k.to_s] = v.to_s }

      presigned_url(
        bucket: bucket,
        key: key,
        method: method,
        expires: expires,
        include_port: include_port,
        force_path_style: force_path_style,
        signer: signer,

        additional_options: opts,
      )
    end

    def presigned_url(
      bucket : String,
      key : String,
      method : Symbol = :get,
      expires : Int32 = 86_400,
      include_port : Bool = false,
      force_path_style : Bool = false,
      signer : Symbol = :v4,
      additional_options : Hash(String, String) = Hash(String, String).new,
    )
      options = Presigned::Url::Options.new(
        aws_access_key: @aws_access_key,
        aws_secret_key: @aws_secret_key,
        region: @region,
        bucket: bucket,
        endpoint: @endpoint.to_s,
        expires: expires,
        object: key,
        include_port: include_port,
        force_path_style: force_path_style,
        signer: signer,
        additional_options: additional_options,
      )

      Presigned::Url.new(options).for(method)
    end
  end
end
