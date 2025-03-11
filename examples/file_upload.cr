require "../src/awscr-s3"

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
  uploader = Awscr::S3::FileUploader.new(client)

  File.open(File.expand_path("README.md"), "r") do |file|
    puts uploader.upload(BUCKET, "someobjectkey", file)
  end
rescue ex : Awscr::S3::InvalidAccessKeyId
  puts ex
end
