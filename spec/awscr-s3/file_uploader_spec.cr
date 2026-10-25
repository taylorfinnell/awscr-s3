require "../spec_helper"

module Awscr::S3
  describe FileUploader do
    describe "when the file is smaller than 5MB" do
      it "uploads it in one call" do
        WebMock.stub(:put, "https://s3.amazonaws.com/bucket/object?")
          .with(body: "document")
          .to_return(status: 200, body: "", headers: {"ETag" => "etag"})

        client = Client.new("us-east-1", "key", "secret")
        uploader = FileUploader.new(client)
        small_io = IO::Memory.new("document")

        uploader.upload("bucket", "object", small_io).should be_true
      end

      it "passes additional headers, when provided" do
        WebMock.stub(:put, "https://s3.amazonaws.com/bucket/object?")
          .with(body: "document", headers: {"x-amz-meta-name" => "myobject"})
          .to_return(status: 200, body: "", headers: {"ETag" => "etag"})

        client = Client.new("us-east-1", "key", "secret")
        uploader = FileUploader.new(client)
        small_io = IO::Memory.new("document")

        uploader.upload("bucket", "object", small_io, {"x-amz-meta-name" => "myobject"}).should be_true
      end
    end

    describe "when the file is larger than 5MB" do
      it "uploads it in chunks" do
        # Start multipart upload
        WebMock.stub(:post, "https://s3.amazonaws.com/bucket/object")
          .with(query: {"uploads" => ""})
          .to_return(status: 200, body: Fixtures.start_multipart_upload_response(upload_id: "123"))

        # Upload part 1
        WebMock.stub(:put, "https://s3.amazonaws.com/bucket/object")
          .with(query: {"partNumber" => "1", "uploadId" => "123"})
          .to_return(status: 200, body: "", headers: {"ETag" => "etag"})

        # Upload part 2
        WebMock.stub(:put, "https://s3.amazonaws.com/bucket/object")
          .with(query: {"partNumber" => "2", "uploadId" => "123"})
          .to_return(status: 200, body: "", headers: {"ETag" => "etag"})

        # Complete multipart upload
        WebMock.stub(:post, "https://s3.amazonaws.com/bucket/object?uploadId=123")
          .with(body: "<?xml version=\"1.0\"?>\n<CompleteMultipartUpload><Part><PartNumber>1</PartNumber><ETag>etag</ETag></Part><Part><PartNumber>2</PartNumber><ETag>etag</ETag></Part></CompleteMultipartUpload>\n")
          .to_return(status: 200, body: Fixtures.complete_multipart_upload_response)

        client = Client.new("us-east-1", "key", "secret")
        uploader = FileUploader.new(client)
        big_io = IO::Memory.new("a" * 5_500_000)

        uploader.upload("bucket", "object", big_io).should be_true
      end

      it "passes additional headers, when provided" do
        # Start multipart upload
        WebMock.stub(:post, "https://s3.amazonaws.com/bucket/object")
          .with(query: {"uploads" => ""}, headers: {"x-amz-meta-name" => "myobject"})
          .to_return(status: 200, body: Fixtures.start_multipart_upload_response(upload_id: "123"))

        # Upload part 1
        WebMock.stub(:put, "https://s3.amazonaws.com/bucket/object")
          .with(query: {"partNumber" => "1", "uploadId" => "123"})
          .to_return(status: 200, body: "", headers: {"ETag" => "etag"})

        # Upload part 2
        WebMock.stub(:put, "https://s3.amazonaws.com/bucket/object")
          .with(query: {"partNumber" => "2", "uploadId" => "123"})
          .to_return(status: 200, body: "", headers: {"ETag" => "etag"})

        # Complete multipart upload
        WebMock.stub(:post, "https://s3.amazonaws.com/bucket/object?uploadId=123")
          .with(body: "<?xml version=\"1.0\"?>\n<CompleteMultipartUpload><Part><PartNumber>1</PartNumber><ETag>etag</ETag></Part><Part><PartNumber>2</PartNumber><ETag>etag</ETag></Part></CompleteMultipartUpload>\n")
          .to_return(status: 200, body: Fixtures.complete_multipart_upload_response)

        client = Client.new("us-east-1", "key", "secret")
        uploader = FileUploader.new(client)
        big_io = IO::Memory.new("a" * 5_500_000)

        uploader.upload("bucket", "object", big_io, {"x-amz-meta-name" => "myobject"}).should be_true
      end
    end

    describe "when the input is a file" do
      it "automatically assigns a content-type header" do
        WebMock.stub(:put, "https://s3.amazonaws.com/bucket/object?")
          .with(body: "", headers: {"Content-Type" => "image/svg+xml"})
          .to_return(status: 200, body: "", headers: {"ETag" => "etag"})

        client = Client.new("us-east-1", "key", "secret")
        uploader = FileUploader.new(client)

        tempfile = File.tempfile("foo", ".svg")
        file = File.open(tempfile.path)

        uploader.upload("bucket", "object", file).should be_true
        tempfile.delete
      end

      it "doesn't assign a content-type header if config.with_content_types is false" do
        WebMock.stub(:put, "https://s3.amazonaws.com/bucket/object?")
          .to_return do |request|
            # Note: Make sure the Content-Type header isn't there
            request.headers.has_key?("Content-Type").should be_false

            headers = HTTP::Headers.new.merge!({"ETag" => "etag"})
            HTTP::Client::Response.new(200, body: "", headers: headers)
          end

        client = Client.new("us-east-1", "key", "secret")
        options = FileUploader::Options.new(with_content_types: false)
        uploader = FileUploader.new(client, options)

        tempfile = File.tempfile("foo", ".svg")
        file = File.open(tempfile.path)

        uploader.upload("bucket", "object", file).should be_true
        tempfile.delete
      end
    end

    describe "when the input is a non-seekable stream (like a pipe)" do
      it "uploads small stream in one call when Content-Length is provided and below threshold" do
        WebMock.stub(:put, "https://s3.amazonaws.com/bucket/object?")
          .with(headers: {"Content-Length" => "100"})
          .to_return(status: 200, body: "", headers: {"ETag" => "etag"})

        client = Client.new("us-east-1", "key", "secret")
        uploader = FileUploader.new(client)

        r, w = IO.pipe
        w.write(Bytes.new(100, 65_u8))
        w.close

        uploader.upload("bucket", "object", r, {"Content-Length" => "100"}).should be_true
      end

      it "uploads stream via multipart upload when size is unknown upfront" do
        WebMock.stub(:post, "https://s3.amazonaws.com/bucket/object")
          .with(query: {"uploads" => ""})
          .to_return(status: 200, body: Fixtures.start_multipart_upload_response(upload_id: "pipe123"))

        WebMock.stub(:put, "https://s3.amazonaws.com/bucket/object")
          .with(query: {"partNumber" => "1", "uploadId" => "pipe123"})
          .to_return(status: 200, body: "", headers: {"ETag" => "etag"})

        WebMock.stub(:post, "https://s3.amazonaws.com/bucket/object?uploadId=pipe123")
          .with(body: "<?xml version=\"1.0\"?>\n<CompleteMultipartUpload><Part><PartNumber>1</PartNumber><ETag>etag</ETag></Part></CompleteMultipartUpload>\n")
          .to_return(status: 200, body: Fixtures.complete_multipart_upload_response)

        client = Client.new("us-east-1", "key", "secret")
        uploader = FileUploader.new(client)

        r, w = IO.pipe
        w.write("data from pipe".to_slice)
        w.close

        uploader.upload("bucket", "object", r).should be_true
      end
    end
  end
end
