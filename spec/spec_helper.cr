require "spec"
require "timecop"
require "webmock"
require "./fixtures"

Spec.before_each do
  WebMock.reset
end

Spec.after_each do
  Timecop.return
end

require "../src/awscr-s3"
