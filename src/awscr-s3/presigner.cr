module Awscr::S3
  class Presigner
    MAX_TTL = 86_400

    def initialize(client : Client)
      @aws_access_key = client.aws_access_key
      @aws_secret_key = client.aws_secret_key
      @endpoint = client.endpoint
      @region = client.region
    end

    def presigned_form(
      bucket : String,
      key : String? = nil,
      aws_session_key : String? = nil,
      expires : Int32 = MAX_TTL,
      acl : String? = nil,
      content_type : String? = nil,
      success_action_status : String? = nil,
      signer : Symbol = :v4,
      conditions : Hash(String, String) = Hash(String, String).new,
    )
      presigned_form(
        bucket: bucket,
        key: key,
        aws_session_key: aws_session_key,
        expires: expires,
        acl: acl,
        content_type: content_type,
        success_action_status: success_action_status,
        signer: signer,
        conditions: conditions
      ) do |_policy|
      end
    end

    def presigned_form(
      bucket : String,
      key : String? = nil,
      aws_session_key : String? = nil,
      expires : Int32 = MAX_TTL,
      acl : String? = nil,
      content_type : String? = nil,
      success_action_status : String? = nil,
      signer : Symbol = :v4,
      conditions : Hash(String, String) = Hash(String, String).new,
      & : Awscr::S3::Presigned::Policy ->
    )
      raise ArgumentError.new("expires must be 1..604800") if expires <= 0 || expires > 604_800

      form = Awscr::S3::Presigned::Form.build(
        @region,
        @aws_access_key,
        @aws_secret_key,
        aws_session_key,
        signer) do |f|
        f.expiration(Time.unix(Time.utc.to_unix + expires))

        f.condition("bucket", bucket)
        f.condition("key", key) if key
        f.condition("acl", acl) if acl
        f.condition("Content-Type", content_type) if content_type
        f.condition("success_action_status", success_action_status) if success_action_status

        conditions.each { |k, v| f.condition(k, v) }

        yield f
      end

      form
    end

    def presigned_url(
      bucket : String,
      key : String,
      method : Symbol = :get,
      expires : Int32 = MAX_TTL,
      include_port : Bool = false,
      force_path_style : Bool = false,
      signer : Symbol = :v4,
      **kwargs,
    )
      opts = {} of String => String
      kwargs.each { |k, v| opts[k.to_s.gsub("_", "-")] = v.to_s }

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
      expires : Int32 = MAX_TTL,
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
