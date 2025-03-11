require "../src/awscr-s3"

Log.setup_from_env

BUCKET = ENV.fetch("AWS_BUCKET", "examplebucket")
KEY    = ENV.fetch("AWS_KEY", "AKIAIOSFODNN7EXAMPLE")
SECRET = ENV.fetch("AWS_SECRET", "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY")
REGION = ENV.fetch("AWS_REGION", "us-east-1")

client = Awscr::S3::Client.new(
  region: REGION,
  aws_access_key: KEY,
  aws_secret_key: SECRET
)

begin
  client.list_objects(bucket: BUCKET, max_keys: 10).each do |response|
    keys = response.contents.sort_by(&.last_modified).map(&.key)
    p keys
  end
rescue ex : Awscr::S3::InvalidAccessKeyId
  puts ex
end
