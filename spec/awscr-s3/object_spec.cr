require "../spec_helper"

module Awscr::S3
  OBJECT_TEST_TIME = Time.utc(2019, 3, 2, 3, 9, 4)

  describe Object do
    it "is equal to another object if key size and etag are same" do
      object = Object.new("test", 123, "etag", OBJECT_TEST_TIME)
      Object.new("test", 123, "etag", OBJECT_TEST_TIME).should eq(object)
    end

    it "not equal to another object key size and etag" do
      object = Object.new("test2", 123, "etag", OBJECT_TEST_TIME)
      (Object.new("test", 123, "asd", OBJECT_TEST_TIME) == object).should eq(false)
    end

    it "has key" do
      object = Object.new("test", 123, "etag", OBJECT_TEST_TIME)
      object.key.should eq("test")
    end

    it "has size" do
      object = Object.new("test", 123, "etag", OBJECT_TEST_TIME)
      object.size.should eq(123)
    end

    it "has etag" do
      object = Object.new("test", 123, "etag", OBJECT_TEST_TIME)
      object.etag.should eq("etag")
    end

    it "has last_modified" do
      object = Object.new("test", 123, "etag", OBJECT_TEST_TIME)
      object.last_modified.should eq(OBJECT_TEST_TIME)
      object.last_modified.utc?.should be_true
    end
  end
end
