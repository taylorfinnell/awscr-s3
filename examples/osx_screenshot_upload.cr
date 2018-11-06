# Upload a screenshot to S3 by submiting a presigned form

require "../src/awscr-s3"
require "uuid"

BUCKET = ENV["AWS_BUCKET"]
HOST   = "#{BUCKET}.s3.amazonaws.com"
KEY    = ENV["AWS_KEY"]
SECRET = ENV["AWS_SECRET"]
REGION = ENV["AWS_REGION"]

form = Awscr::S3::Presigned::Form.build(REGION, KEY, SECRET) do |f|
  f.expiration(Time.unix(Time.now.to_unix + 1000))
  f.condition("bucket", BUCKET)
  f.condition("acl", "public-read")
  f.condition("key", "#{UUID.random}.png"[0...8])
  f.condition("Content-Type", "image/png")
  f.condition("success_action_status", "201")
end

path = "/tmp/#{UUID.random}"
`screencapture -i #{path}`

file = File.open(path)
resp = form.submit(file)

if resp.status_code == 201
  puts "Upload was a success: #{resp.headers["Location"]}"
else
  puts "Upload failed: #{resp.status_code}:\n\n#{resp.body}"
end

File.delete(path)
