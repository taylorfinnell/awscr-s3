require "../src/awscr-s3"
require "uuid"

Log.setup_from_env

BUCKET = ENV.fetch("AWS_BUCKET", "examplebucket")
KEY    = ENV.fetch("AWS_KEY", "AKIAIOSFODNN7EXAMPLE")
SECRET = ENV.fetch("AWS_SECRET", "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY")
REGION = ENV.fetch("AWS_REGION", "us-east-1")

form = Awscr::S3::Presigned::Form.build(REGION, KEY, SECRET) do |f|
  f.expiration(Time.utc + 1.second)
  f.condition("bucket", BUCKET)
  f.condition("acl", "public-read")
  f.condition("key", "#{UUID.random}.png"[0...8])
  f.condition("Content-Type", "image/png")
  f.condition("success_action_status", "201")
end

path = "/tmp/#{UUID.random}"
`date >> #{path}`

file = File.open(path)
resp = form.submit(file)

if resp.status_code == 201
  puts "Upload was a success: #{resp.headers["Location"]}"
else
  puts "Upload failed: #{resp.status_code}:\n\n#{resp.body}"
end

File.delete(path)
