require "spec"
require "timecop"
require "webmock"

struct Time
  def self.utc_now
    Timecop.now
  end
end

require "../src/awscr-s3"
