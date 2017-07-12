# Get raw html for an S3 upload form

require "../src/awscr-s3"
require "secure_random"

BUCKET = ENV["AWS_BUCKET"]
HOST   = "#{BUCKET}.s3.amazonaws.com"
KEY    = ENV["AWS_KEY"]
SECRET = ENV["AWS_SECRET"]
REGION = ENV["AWS_REGION"]

form = Awscr::S3::Presigned::Form.build(region: REGION, aws_access_key: KEY,
                                           aws_secret_key: SECRET) do |form|
  form.expiration(Time.epoch(Time.now.epoch + 1000))
  form.condition("bucket", BUCKET)
  form.condition("acl", "public-read")
  form.condition("key", SecureRandom.uuid)
  form.condition("Content-Type", "text/plain")
  form.condition("success_action_status", "201")
end

# The following HTML represents a valid form. Try writing the
# HTML to a file and opening it in your browser. You will be
# presented with a small upload form to upload directly from
# your browser.
#
# You may access the fields via form#fields.
# You may access the url via form#url.
puts form.to_html
