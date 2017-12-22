require "../spec_helper"

module Awscr::S3
  describe Bucket do
    it "is equal to another bucket if name and creation time are equal" do
      bucket = Bucket.new("test", "123")
      Bucket.new("test", "123").should eq(bucket)
    end

    it "not equal to another bucket if name and creation time differ" do
      bucket = Bucket.new("test2", "123")
      (Bucket.new("test", "123") == bucket).should eq(false)
    end
  end
end
