require "../../spec_helper"

module Awscr
  module S3
    module Response
      describe CompleteMultipartUpload do
        describe "equality" do
          it "is equal if key, location, and etag are equal" do
            status = HTTP::Status.new(200)
            CompleteMultipartUpload.new("location", "key", "etag", status, "OK").should eq(
              CompleteMultipartUpload.new("location", "key", "etag", status, "OK")
            )
          end

          it "is not equal if key, location, or etag are diff" do
            status = HTTP::Status.new(200)
            (CompleteMultipartUpload.new("location", "key", "etag1", status, "OK") ==
              CompleteMultipartUpload.new("location", "key", "etag", status, "OK")).should be_false
          end
        end
      end
    end
  end
end
