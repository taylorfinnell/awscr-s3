require "../spec_helper"

module Awscr::S3
  describe Object do
    it "is equal to another object if key size and etag are same" do
      object = Object.new("test", 123, "etag", "2019-03-02T03:09:04.057Z")
      Object.new("test", 123, "etag", "2019-03-02T03:09:04.057Z").should eq(object)
    end

    it "not equal to another object key size and etag" do
      object = Object.new("test2", 123, "etag", "2019-03-02T03:09:04.057Z")
      (Object.new("test", 123, "asd", "2019-03-02T03:09:04.057Z") == object).should eq(false)
    end

    it "has key" do
      object = Object.new("test", 123, "etag", "2019-03-02T03:09:04.057Z")
      object.key.should eq("test")
    end

    it "has size" do
      object = Object.new("test", 123, "etag", "2019-03-02T03:09:04.057Z")
      object.size.should eq(123)
    end

    it "has etag" do
      object = Object.new("test", 123, "etag", "2019-03-02T03:09:04.057Z")
      object.etag.should eq("etag")
    end
    it "has etag" do
      object = Object.new("test", 123, "etag", "2019-03-02T03:09:04.057Z")
      object.last_modified.should eq("2019-03-02T03:09:04.057Z")
    end
  end
end
