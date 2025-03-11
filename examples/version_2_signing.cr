require "../src/awscr-s3"
require "uuid"

BUCKET = ENV.fetch("AWS_BUCKET", "examplebucket")
KEY    = ENV.fetch("AWS_KEY", "AKIAIOSFODNN7EXAMPLE")
SECRET = ENV.fetch("AWS_SECRET", "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY")
REGION = ENV.fetch("AWS_REGION", "us-east-1")

object = "/#{UUID.random}"

options = Awscr::S3::Presigned::Url::Options.new(
  region: REGION,
  object: object,
  bucket: BUCKET,
  aws_access_key: KEY,
  aws_secret_key: SECRET,
  signer: :v2
)

url = Awscr::S3::Presigned::Url.new(options)

HTTP::Client.put(url.for(:put), HTTP::Headers.new, body: "Howdy!")
resp = HTTP::Client.get(url.for(:get))
p "Object #{object}: #{resp.body}"
