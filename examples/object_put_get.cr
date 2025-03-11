require "../src/awscr-s3"
require "uuid"

BUCKET = ENV.fetch("AWS_BUCKET", "examplebucket")
KEY    = ENV.fetch("AWS_KEY", "AKIAIOSFODNN7EXAMPLE")
SECRET = ENV.fetch("AWS_SECRET", "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY")
REGION = ENV.fetch("AWS_REGION", "us-east-1")

client = Awscr::S3::Client.new(
  region: REGION,
  aws_access_key: KEY,
  aws_secret_key: SECRET
)

object = UUID.random.to_s

begin
  client.put_object(bucket: BUCKET, object: object, body: IO::Memory.new("Hey!"))

  resp = client.get_object(bucket: BUCKET, object: object)
  puts resp.body
rescue ex : Awscr::S3::InvalidAccessKeyId
  puts ex
end
