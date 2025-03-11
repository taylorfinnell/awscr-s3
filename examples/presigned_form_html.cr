# Get raw html for an S3 upload form

require "../src/awscr-s3"
require "uuid"

SERVICE = "s3"
BUCKET  = ENV.fetch("AWS_BUCKET", "examplebucket")
KEY     = ENV.fetch("AWS_KEY", "AKIAIOSFODNN7EXAMPLE")
SECRET  = ENV.fetch("AWS_SECRET", "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY")
REGION  = ENV.fetch("AWS_REGION", "us-east-1")
HOST    = "#{BUCKET}.#{SERVICE}.amazonaws.com"

form = Awscr::S3::Presigned::Form.build(
  region: REGION,
  aws_access_key: KEY,
  aws_secret_key: SECRET) do |f|
  f.expiration(Time.utc + 1.second)
  f.condition("bucket", BUCKET)
  f.condition("acl", "public-read")
  f.condition("key", UUID.random.to_s)
  f.condition("Content-Type", "text/plain")
  f.condition("success_action_status", "201")
end

# The following HTML represents a valid form. Try writing the
# HTML to a file and opening it in your browser. You will be
# presented with a small upload form to upload directly from
# your browser.
#
# You may access the fields via form#fields.
# You may access the url via form#url.
puts form.to_html
