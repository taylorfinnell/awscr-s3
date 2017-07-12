require "../src/awscr-s3"
require "secure_random"

BUCKET = ENV["AWS_BUCKET"]
HOST   = "#{BUCKET}.s3.amazonaws.com"
KEY    = ENV["AWS_KEY"]
SECRET = ENV["AWS_SECRET"]
REGION = ENV["AWS_REGION"]

creds = Awscr::Signer::Credentials.new(KEY, SECRET)

object = "/#{SecureRandom.uuid}"

options = Awscr::S3::Presigned::Url::Options.new(object: object, bucket: BUCKET, additional_options: {
  "x-amz-acl"    => "public-read",
  "Content-Type" => "image/png",
})

url = Awscr::S3::Presigned::Url.new(REGION, creds, options)

HTTP::Client.put(url.for(:put), HTTP::Headers.new, body: "Howdy!")
resp = HTTP::Client.get(url.for(:get))
p "Object #{object}: #{resp.body}"
