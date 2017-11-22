require "../../spec_helper"

module Awscr
  module S3
    module Response
      describe CompleteMultipartUpload do
        describe "equality" do
          it "is equal if key, location, and etag are equal" do
            CompleteMultipartUpload.new("location", "key", "etag").should eq(
              CompleteMultipartUpload.new("location", "key", "etag")
            )
          end

          it "is not equal if key, location, or etag are diff" do
            (CompleteMultipartUpload.new("location", "key", "etag1") ==
              CompleteMultipartUpload.new("location", "key", "etag")).should be_false
          end
        end
      end
    end
  end
end
