require "spec"
require "timecop"

struct Time
  def self.utc_now
    Timecop.now
  end
end

require "../src/awscr-s3"

