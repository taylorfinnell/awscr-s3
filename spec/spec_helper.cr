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

require "../src/awscr-s3"
