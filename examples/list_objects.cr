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

client.list_objects(bucket: BUCKET, max_keys: 10).each do |response|
  keys = response.contents.sort_by(&.last_modified).map(&.key)
  p keys
end
