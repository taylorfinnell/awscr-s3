require "spec"
require "timecop"
require "webmock"
require "./fixtures"

Spec.around_each do |example|
  WebMock.reset
  # Integration tests should allow to send requests
  integration = example.example.all_tags.includes?("integration") || \
     example.example.file.includes?("spec/integration")
  WebMock.allow_net_connect = integration

  example.run
end

Spec.after_each do
  Timecop.return
end

S3_HOST         = "127.0.0.1:9000"
S3_ENDPOINT     = "http://#{S3_HOST}"
S3_ENDPOINT_URL = URI.parse(S3_ENDPOINT)

require "../src/awscr-s3"
require "./support/**"
