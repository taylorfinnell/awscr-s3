# Upload a screenshot to S3 by submiting a presigned form

require "../src/awscr-s3"
require "secure_random"
require "tempfile"

BUCKET = ENV["AWS_BUCKET"]
HOST   = "#{BUCKET}.s3.amazonaws.com"
KEY    = ENV["AWS_KEY"]
SECRET = ENV["AWS_SECRET"]
REGION = ENV["AWS_REGION"]

creds = Awscr::Signer::Credentials.new(KEY, SECRET)

form = Awscr::Signer::Presigned::Form.build(REGION, creds) do |form|
  form.expiration(Time.epoch(Time.now.epoch + 1000))
  form.condition("bucket", BUCKET)
  form.condition("acl", "public-read")
  form.condition("key", "#{SecureRandom.uuid}.png"[0...8])
  form.condition("Content-Type", "image/png")
  form.condition("success_action_status", "201")
end

path = "/tmp/#{SecureRandom.uuid}"
`screencapture -i #{path}`

file = File.open(path)
resp = form.submit(file)

if resp.status_code == 201
  puts "Upload was a success: #{resp.headers["Location"]}"
else
  puts "Upload failed: #{resp.status_code}:\n\n#{resp.body}"
end

File.delete(path)
