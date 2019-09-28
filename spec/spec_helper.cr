require "spec"
require "timecop"
require "webmock"
require "./fixtures"

Spec.before_each do
  WebMock.reset
end

require "../src/awscr-s3"
