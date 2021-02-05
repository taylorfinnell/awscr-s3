require "../spec_helper"

module Awscr::S3
  describe ObjectIdEncoder do
    it "encodes test cases correctly" do
      [
        {object_id: "notes/object.txt", expected: "notes/object.txt"},
        {object_id: "test=", expected: "test%3D"},
        {object_id: "test object", expected: "test+object"},
        {object_id: "test'", expected: "test%27"},
      ].each do |test_case|
        ObjectIdEncoder.encode(test_case[:object_id]).should eq(test_case[:expected])
      end
    end
  end
end
