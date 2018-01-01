require "../src/awscr-s3"
require "uuid"

BUCKET = ENV["AWS_BUCKET"]
KEY    = ENV["AWS_KEY"]
SECRET = ENV["AWS_SECRET"]
REGION = ENV["AWS_REGION"]

client = Awscr::S3::Client.new(
  region: REGION,
  aws_access_key: KEY,
  aws_secret_key: SECRET
)

object = UUID.random.to_s

client.put_object(bucket: BUCKET, object: object, body: IO::Memory.new("Hey!"))

resp = client.get_object(bucket: BUCKET, object: object)
puts resp.body
