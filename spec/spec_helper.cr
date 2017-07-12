require "spec"
require "timecop"

# Monkey patch Time\Timecop
struct Time
  def self.utc_now
    Timecop.now
  end
end

require "../src/awscr-s3"
