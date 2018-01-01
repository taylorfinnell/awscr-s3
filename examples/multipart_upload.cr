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

upload = client.start_multipart_upload(
  bucket: BUCKET,
  object: object
)

uploaded_part = client.upload_part(
  bucket: BUCKET,
  object: object,
  upload_id: upload.upload_id,
  part_number: 1,
  part: IO::Memory.new("A" * 5_000_001) # 5mb min
)

final = client.complete_multipart_upload(
  bucket: BUCKET,
  object: object,
  upload_id: upload.upload_id,
  parts: [uploaded_part]
)

p final.inspect
