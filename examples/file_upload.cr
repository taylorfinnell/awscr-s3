require "../src/awscr-s3"

BUCKET = ENV["AWS_BUCKET"]
KEY    = ENV["AWS_KEY"]
SECRET = ENV["AWS_SECRET"]
REGION = ENV["AWS_REGION"]

client = Awscr::S3::Client.new(
  region: REGION,
  aws_access_key: KEY,
  aws_secret_key: SECRET
)

uploader = Awscr::S3::FileUploader.new(client)

File.open(File.expand_path("~/Downloads/EasyTomato_0.8.trx"), "r") do |file|
  puts uploader.upload(BUCKET, "someobjectkey", file)
end
