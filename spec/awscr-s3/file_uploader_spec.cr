require "../../spec_helper"

module Awscr::S3
  describe FileUploader do
    describe "when the file is smaller than 5MB" do
      it "uploads it in one call" do
        WebMock.stub(:put, "http://s3.amazonaws.com/bucket/object?")
               .with(body: "document")
               .to_return(status: 200, body: "", headers: {"ETag" => "etag"})

        client = Client.new("us-east-1", "key", "secret")
        uploader = FileUploader.new(client)
        small_io = IO::Memory.new("document")

        uploader.upload("bucket", "object", small_io)
      end

      it "passes additional headers, when provided" do
        WebMock.stub(:put, "http://s3.amazonaws.com/bucket/object?")
               .with(body: "document", headers: {"x-amz-meta-name" => "myobject"})
               .to_return(status: 200, body: "", headers: {"ETag" => "etag"})

        client = Client.new("us-east-1", "key", "secret")
        uploader = FileUploader.new(client)
        small_io = IO::Memory.new("document")

        uploader.upload("bucket", "object", small_io, {"x-amz-meta-name" => "myobject"})
      end
    end

    describe "when the file is larger than 5MB" do
      it "uploads it in chunks" do
        # Start multipart upload
        WebMock.stub(:post, "http://s3.amazonaws.com/bucket/object")
               .with(query: {"uploads" => ""})
               .to_return(status: 200, body: Fixtures.start_multipart_upload_response(upload_id: "123"))

        # Upload part 1
        WebMock.stub(:put, "http://s3.amazonaws.com/bucket/object")
               .with(query: {"partNumber" => "1", "uploadId" => "123"})
               .to_return(status: 200, body: "", headers: {"ETag" => "etag"})

        # Upload part 2
        WebMock.stub(:put, "http://s3.amazonaws.com/bucket/object")
               .with(query: {"partNumber" => "2", "uploadId" => "123"})
               .to_return(status: 200, body: "", headers: {"ETag" => "etag"})

        # Complete multipart upload
        WebMock.stub(:post, "http://s3.amazonaws.com/bucket/object?uploadId=123")
               .with(body: "<?xml version=\"1.0\"?>\n<CompleteMultipartUpload><Part><PartNumber>1</PartNumber><ETag>etag</ETag></Part><Part><PartNumber>2</PartNumber><ETag>etag</ETag></Part></CompleteMultipartUpload>\n")
               .to_return(status: 200, body: Fixtures.complete_multipart_upload_response)

        client = Client.new("us-east-1", "key", "secret")
        uploader = FileUploader.new(client)
        big_io = IO::Memory.new("a" * 5_500_000)

        uploader.upload("bucket", "object", big_io)
      end

      it "passes additional headers, when provided" do
        # Start multipart upload
        WebMock.stub(:post, "http://s3.amazonaws.com/bucket/object")
               .with(query: {"uploads" => ""}, headers: {"x-amz-meta-name" => "myobject"})
               .to_return(status: 200, body: Fixtures.start_multipart_upload_response(upload_id: "123"))

        # Upload part 1
        WebMock.stub(:put, "http://s3.amazonaws.com/bucket/object")
               .with(query: {"partNumber" => "1", "uploadId" => "123"})
               .to_return(status: 200, body: "", headers: {"ETag" => "etag"})

        # Upload part 2
        WebMock.stub(:put, "http://s3.amazonaws.com/bucket/object")
               .with(query: {"partNumber" => "2", "uploadId" => "123"})
               .to_return(status: 200, body: "", headers: {"ETag" => "etag"})

        # Complete multipart upload
        WebMock.stub(:post, "http://s3.amazonaws.com/bucket/object?uploadId=123")
               .with(body: "<?xml version=\"1.0\"?>\n<CompleteMultipartUpload><Part><PartNumber>1</PartNumber><ETag>etag</ETag></Part><Part><PartNumber>2</PartNumber><ETag>etag</ETag></Part></CompleteMultipartUpload>\n")
               .to_return(status: 200, body: Fixtures.complete_multipart_upload_response)

        client = Client.new("us-east-1", "key", "secret")
        uploader = FileUploader.new(client)
        big_io = IO::Memory.new("a" * 5_500_000)

        uploader.upload("bucket", "object", big_io, {"x-amz-meta-name" => "myobject"})
      end
    end
  end
end
