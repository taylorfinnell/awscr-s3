require "spec"
require "timecop"
require "webmock"
require "./fixtures"

struct Time
  def self.utc_now
    Timecop.now
  end
end

struct ObjectHelper
  def self.equal?(o1, o2)
    o1.key == o2.key &&
      o1.size == o2.size &&
      o1.etag == o2.etag &&
      o1.last_modified == o2.last_modified
  end
end

Spec.before_each do
  WebMock.reset
end

require "../src/awscr-s3"
