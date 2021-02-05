require "../spec_helper"

module Awscr::S3
  TEST_TIME_1 = Time.utc(2009, 9, 11, 17, 50, 30)
  TEST_TIME_2 = Time.utc(2010, 10, 12, 17, 50, 30)

  describe Client do
    it "allows signer version" do
      Client.new("adasd", "adasd", "adad", signer: :v2)
    end

    describe "batch_delete" do
      it "can can fail to delete items" do
        xml = <<-XML
          <?xml version="1.0" encoding="UTF-8"?>
          <DeleteResult xmlns="https://s3.amazonaws.com/doc/2006-03-01/">
            <Deleted>
              <Key>testkey</Key>
              <Code>AccessDenied</Code>
              <Message>Access Denied</Message>
            </Deleted>
          </DeleteResult>
        XML

        WebMock.stub(:post, "https://s3.amazonaws.com/bucket?delete")
          .with(body: "<?xml version=\"1.0\"?>\n<Delete><Object><Key>testkey</Key></Object></Delete>\n", headers: {"Content-MD5" => "Slga5acph5mH0Gagq5P2BQ==", "Content-Length" => "75"})
          .to_return(body: xml)

        client = Client.new("us-east-1", "key", "secret")
        result = client.batch_delete("bucket", ["testkey"])

        result.should be_a(Response::BatchDeleteOutput)
        result.success?.should be_false
        result.deleted_objects.should eq([] of Response::BatchDeleteOutput::DeletedObject)
        result.failed_objects.should eq([Response::BatchDeleteOutput::DeletedObject.new("testkey", "AccessDenied", "Access Denied")])
      end

      it "can can successfully delete items" do
        xml = <<-XML
          <?xml version="1.0" encoding="UTF-8"?>
          <DeleteResult xmlns="https://s3.amazonaws.com/doc/2006-03-01/">
            <Deleted>
              <Key>testkey</Key>
            </Deleted>
          </DeleteResult>
        XML

        WebMock.stub(:post, "https://s3.amazonaws.com/bucket?delete")
          .with(body: "<?xml version=\"1.0\"?>\n<Delete><Object><Key>testkey</Key></Object></Delete>\n", headers: {"Content-MD5" => "Slga5acph5mH0Gagq5P2BQ==", "Content-Length" => "75"})
          .to_return(body: xml)

        client = Client.new("us-east-1", "key", "secret")
        result = client.batch_delete("bucket", ["testkey"])

        result.should be_a(Response::BatchDeleteOutput)
        result.success?.should be_true
        result.failed_objects.should eq([] of Response::BatchDeleteOutput::DeletedObject)
        result.deleted_objects.should eq([Response::BatchDeleteOutput::DeletedObject.new("testkey", "", "")])
      end

      it "raises if too many keys" do
        keys = ["test"] * 1001

        client = Client.new("us-east-1", "key", "secret")

        expect_raises S3::Exception do
          client.batch_delete("bucket", keys)
        end
      end
    end

    describe "put_bucket" do
      it "creates a bucket" do
        WebMock.stub(:put, "https://s3.amazonaws.com/bucket")
          .to_return(body: "")

        client = Client.new("us-east-1", "key", "secret")
        result = client.put_bucket("bucket")

        result.should be_true
      end

      it "can create a bucket with a region" do
        body = "<?xml version=\"1.0\"?>\n<CreateBucketConfiguration><LocationConstraint>us-west-2</LocationConstraint></CreateBucketConfiguration>\n"

        WebMock.stub(:put, "https://s3.amazonaws.com/bucket2")
          .with(body: body)
          .to_return(body: "")

        client = Client.new("us-east-1", "key", "secret")
        result = client.put_bucket("bucket2", region: "us-west-2")

        result.should be_true
      end
    end

    describe "delete_bucket" do
      it "returns true when buckest is deleted" do
        WebMock.stub(:delete, "https://s3.amazonaws.com/bucket")
          .to_return(body: "", status: 204)

        client = Client.new("us-east-1", "key", "secret")
        result = client.delete_bucket("bucket")

        result.should be_true
      end
    end

    describe "abort_multipart_upload" do
      it "aborts an upload" do
        WebMock.stub(:delete, "https://s3.amazonaws.com/bucket/object?uploadId=upload_id")
          .to_return(status: 204)

        client = Client.new("us-east-1", "key", "secret")
        result = client.abort_multipart_upload("bucket", "object", "upload_id")

        result.should be_true
      end
    end

    describe "start_multipart_upload" do
      it "starts a multipart upload" do
        WebMock.stub(:post, "https://s3.amazonaws.com/bucket/object?uploads")
          .to_return(status: 200, body: Fixtures.start_multipart_upload_response)

        client = Client.new("us-east-1", "key", "secret")
        result = client.start_multipart_upload("bucket", "object")

        result.should eq(Response::StartMultipartUpload.new(
          "bucket",
          "object",
          "FxtGq8otGhDtYJa5VYLpPOBQo2niM2a1YR8wgcwqHJ1F1Djflj339mEfpm7NbYOoIg.6bIPeXl2RB82LuAnUkTQUEz_ReIu2wOwawGc0Z4SLERxoXospqANXDazuDmRF"
        ))
      end

      it "passes additional headers, when provided" do
        WebMock.stub(:post, "https://s3.amazonaws.com/bucket/object?uploads")
          .with(headers: {"x-amz-meta-name" => "document"})
          .to_return(status: 200, body: Fixtures.start_multipart_upload_response)

        client = Client.new("us-east-1", "key", "secret")
        client.start_multipart_upload("bucket", "object", headers: {"x-amz-meta-name" => "document"})
      end
    end

    describe "upload_part" do
      it "uploads a part" do
        WebMock.stub(:put, "https://s3.amazonaws.com/bucket2/obj2?partNumber=1&uploadId=123")
          .with(body: "test")
          .to_return(status: 200, body: "", headers: {"ETag" => "etag"})

        client = Client.new("us-east-1", "key", "secret")
        result = client.upload_part("bucket2", "obj2", "123", 1, "test")

        result.should eq(
          Response::UploadPartOutput.new("etag", 1, "123")
        )
      end
    end

    describe "complete_multipart_upload" do
      it "completes a multipart upload" do
        post_body = "<?xml version=\"1.0\"?>\n<CompleteMultipartUpload><Part><PartNumber>1</PartNumber><ETag>etag</ETag></Part></CompleteMultipartUpload>\n"

        WebMock.stub(:post, "https://s3.amazonaws.com/bucket/object?uploadId=upload_id")
          .with(body: post_body)
          .to_return(status: 200, body: Fixtures.complete_multipart_upload_response)

        outputs = [Response::UploadPartOutput.new("etag", 1, "upload_id")]

        client = Client.new("us-east-1", "key", "secret")
        result = client.complete_multipart_upload("bucket", "object", "upload_id", outputs)

        result.should eq(
          Response::CompleteMultipartUpload.new(
            "https://s3.amazonaws.com/screensnapr-development/test",
            "test",
            "\"7611c6414e4b58f22ff9f59a2c1767b7-2\""
          )
        )
      end
    end

    describe "delete_object" do
      it "returns true if object deleted" do
        WebMock.stub(:delete, "https://s3.amazonaws.com/blah/obj?")
          .to_return(status: 204)

        client = Client.new("us-east-1", "key", "secret")
        result = client.delete_object("blah", "obj")

        result.should be_true
      end

      it "passes additional headers, when provided" do
        WebMock.stub(:delete, "https://s3.amazonaws.com/blah/obj?")
          .with(headers: {"x-amz-mfa" => "123456"})
          .to_return(status: 204)

        client = Client.new("us-east-1", "key", "secret")
        client.delete_object("blah", "obj", headers: {"x-amz-mfa" => "123456"})
      end
    end

    describe "put_object" do
      it "can do a basic put" do
        io = IO::Memory.new("Hello")

        WebMock.stub(:put, "https://s3.amazonaws.com/mybucket/object.txt")
          .with(body: "Hello")
          .to_return(body: "", headers: {"ETag" => "etag"})

        client = Client.new("us-east-1", "key", "secret")
        resp = client.put_object("mybucket", "object.txt", io)

        resp.should eq(Response::PutObjectOutput.new("etag"))
      end

      it "passes additional headers, when provided" do
        io = IO::Memory.new("Hello")

        WebMock.stub(:put, "https://s3.amazonaws.com/mybucket/object.txt")
          .with(body: "Hello", headers: {"Content-Length" => "5", "x-amz-meta-name" => "object"})
          .to_return(body: "", headers: {"ETag" => "etag"})

        client = Client.new("us-east-1", "key", "secret")
        client.put_object("mybucket", "object.txt", io, {"x-amz-meta-name" => "object"})
      end
    end

    describe "list_objects" do
      it "handles pagination" do
        resp = <<-RESP
        <?xml version="1.0" encoding="UTF-8"?>
        <ListBucketResult xmlns="https://s3.amazonaws.com/doc/2006-03-01/">
          <Name>bucket</Name>
          <Prefix/>
          <KeyCount>1</KeyCount>
          <MaxKeys>1</MaxKeys>
          <IsTruncated>true</IsTruncated>
          <NextContinuationToken>token</NextContinuationToken
          <Contents>
              <Key>my-image.jpg</Key>
              <LastModified>2009-09-11T17:50:30.000Z</LastModified>
              <ETag>"fba9dede5f27731c9771645a39863328"</ETag>
              <Size>434234</Size>
              <StorageClass>STANDARD</StorageClass>
          </Contents>
        </ListBucketResult>
        RESP

        resp2 = <<-RESP
        <?xml version="1.0" encoding="UTF-8"?>
        <ListBucketResult xmlns="https://s3.amazonaws.com/doc/2006-03-01/">
          <Name>bucket</Name>
          <Prefix/>
          <KeyCount>1</KeyCount>
          <MaxKeys>1</MaxKeys>
          <IsTruncated>false</IsTruncated>
          <Contents>
              <Key>key2</Key>
              <LastModified>2010-10-12T17:50:30.000Z</LastModified>
              <ETag>"fba9dede5f27731c9771645a39863329"</ETag>
              <Size>1337</Size>
              <StorageClass>STANDARD</StorageClass>
          </Contents>
        </ListBucketResult>
        RESP

        WebMock.stub(:get, "https://s3.amazonaws.com/bucket?list-type=2&max-keys=1&continuation-token=token")
          .to_return(body: resp2)

        WebMock.stub(:get, "https://s3.amazonaws.com/bucket?list-type=2&max-keys=1")
          .to_return(body: resp)

        client = Client.new("us-east-1", "key", "secret")

        objects = [] of Response::ListObjectsV2
        client.list_objects("bucket", max_keys: 1).each do |output|
          objects << output
        end

        expected_objects = [
          Object.new("my-image.jpg", 434_234,
            "\"fba9dede5f27731c9771645a39863328\"", TEST_TIME_1),
          Object.new("key2", 1337,
            "\"fba9dede5f27731c9771645a39863329\"", TEST_TIME_2),
        ]

        objects.should eq([
          Response::ListObjectsV2.new("bucket", "", 1, 1, true, "token",
            [expected_objects.first]),
          Response::ListObjectsV2.new("bucket", "", 1, 1, false, "",
            [expected_objects.last]),
        ])
      end

      it "supports basic case" do
        resp = <<-RESP
        <?xml version="1.0" encoding="UTF-8"?>
        <ListBucketResult xmlns="https://s3.amazonaws.com/doc/2006-03-01/">
          <Name>blah</Name>
          <Prefix/>
          <KeyCount>205</KeyCount>
          <MaxKeys>1000</MaxKeys>
          <IsTruncated>false</IsTruncated>
          <Contents>
              <Key>my-image.jpg</Key>
              <LastModified>2009-09-11T17:50:30.000Z</LastModified>
              <ETag>&quot;fba9dede5f27731c9771645a39863328&quot;</ETag>
              <Size>434234</Size>
              <StorageClass>STANDARD</StorageClass>
          </Contents>
          <Contents>
              <Key>key2</Key>
              <LastModified>2010-10-12T17:50:30.000Z</LastModified>
              <ETag>&quot;fba9dede5f27731c9771645a39863329&quot;</ETag>
              <Size>1337</Size>
              <StorageClass>STANDARD</StorageClass>
          </Contents>
        </ListBucketResult>
        RESP

        WebMock.stub(:get, "https://s3.amazonaws.com/blah?list-type=2")
          .to_return(body: resp)

        expected_objects = [
          Object.new("my-image.jpg", 434_234,
            "\"fba9dede5f27731c9771645a39863328\"", TEST_TIME_1),
          Object.new("key2", 1337,
            "\"fba9dede5f27731c9771645a39863329\"", TEST_TIME_2),
        ]

        client = Client.new("us-east-1", "key", "secret")

        client.list_objects("blah").each do |output|
          output.should eq(Response::ListObjectsV2.new("blah", "", 205, 1000, false, "", expected_objects))
        end
      end
    end

    describe "list_buckets" do
      it "returns buckets on success" do
        resp = <<-RESP
        <?xml version="1.0" encoding="UTF-8"?>
        <ListAllMyBucketsResult xmlns="https://s3.amazonaws.com/doc/2006-03-01">
          <Owner>
            <ID>bcaf1ffd86f461ca5fb16fd081034f</ID>
            <DisplayName>webfile</DisplayName>
          </Owner>
          <Buckets>
            <Bucket>
              <Name>quotes</Name>
              <CreationDate>2006-02-03T16:45:09.000Z</CreationDate>
            </Bucket>
          </Buckets>
        </ListAllMyBucketsResult>
        RESP

        WebMock.stub(:get, "https://s3.amazonaws.com/?")
          .to_return(body: resp)

        client = Client.new("us-east-1", "key", "secret")
        output = client.list_buckets

        output.should eq(Response::ListAllMyBuckets.new([
          Bucket.new("quotes", Time.parse!("2006-02-03T16:45:09 +00:00", Response::ListAllMyBuckets::DATE_FORMAT)),
        ]))
      end
    end

    describe "head_bucket" do
      it "raises if bucket does not exist" do
        WebMock.stub(:head, "https://s3.amazonaws.com/blah2?")
          .to_return(status: 404)

        client = Client.new("us-east-1", "key", "secret")

        expect_raises(Exception) do
          client.head_bucket("blah2")
        end
      end

      it "returns true if bucket exists" do
        WebMock.stub(:head, "https://s3.amazonaws.com/blah?")
          .to_return(status: 200)

        client = Client.new("us-east-1", "key", "secret")
        result = client.head_bucket("blah")

        result.should be_true
      end
    end

    describe "custom endpoint" do
      it "can set a custom endpoint" do
        io = IO::Memory.new("Hello")

        WebMock.stub(:put, "https://nyc3.digitaloceanspaces.com/mybucket/object.txt")
          .with(body: "Hello")
          .to_return(body: "", headers: {"ETag" => "etag"})

        client = Client.new("", "key", "secret", "https://nyc3.digitaloceanspaces.com")
        resp = client.put_object("mybucket", "object.txt", io)

        resp.should eq(Response::PutObjectOutput.new("etag"))
      end

      it "can set a custom endpoint with a port" do
        io = IO::Memory.new("Hello")

        WebMock.stub(:put, "http://127.0.0.1:9000/mybucket/object.txt")
          .with(body: "Hello")
          .to_return(body: "", headers: {"ETag" => "etag"})

        client = Client.new("", "key", "secret", "http://127.0.0.1:9000")
        resp = client.put_object("mybucket", "object.txt", io)

        resp.should eq(Response::PutObjectOutput.new("etag"))
      end
    end
  end
end
