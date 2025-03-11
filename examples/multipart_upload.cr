require "../src/awscr-s3"
require "uuid"

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

object = UUID.random.to_s

begin
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
rescue ex : Awscr::S3::InvalidAccessKeyId
  puts ex
end
