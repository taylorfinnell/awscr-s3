require "../../spec_helper"

module Awscr
  module S3
    module Presigned
      describe PostField do
        it "can be compared to a field" do
          field = PostField.new("key", "test")
          field2 = PostField.new("key", "test2")

          (field == field.dup).should be_true
          (field2 == field).should be_false
        end

        it "has a key" do
          field = PostField.new("key", "test")

          field.key.should eq "key"
        end

        it "has a value" do
          field = PostField.new("key", "test")

          field.value.should eq("test")
        end

        it "serializes" do
          field = PostField.new("k", "v")
          field.serialize.should eq({"k" => "v"})
        end
      end
    end
  end
end
