require "../spec_helper"

module Awscr::S3
  describe Util do
    describe "#util" do
      it "encodes test cases correctly" do
        [
          {object_id: "notes/object.txt", expected: "notes/object.txt"},
          {object_id: "test=", expected: "test%3D"},
          {object_id: "test object", expected: "test%20object"},
          {object_id: "test'", expected: "test%27"},
        ].each do |test_case|
          Util.encode(test_case[:object_id]).should eq(test_case[:expected])
        end
      end
    end
  end
end
