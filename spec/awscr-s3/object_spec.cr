require "../spec_helper"

module Awscr::S3
  describe Object do
    it "is equal to another object if key size and etag are same" do
      object = Object.new("test", 123, "etag")
      Object.new("test", 123, "etag").should eq(object)
    end

    it "not equal to another object key size and etag" do
      object = Object.new("test2", 123, "etag")
      (Object.new("test", 123, "asd") == object).should eq(false)
    end

    it "has key" do
      object = Object.new("test", 123, "etag")
      object.key.should eq("test")
    end

    it "has size" do
      object = Object.new("test", 123, "etag")
      object.size.should eq(123)
    end

    it "has etag" do
      object = Object.new("test", 123, "etag")
      object.etag.should eq("etag")
    end
  end
end
