require "../spec_helper"

module Awscr::S3
  describe Client do
    describe "put_object" do
      it "can do a basic put" do
        io = IO::Memory.new("Hello")

        WebMock.stub(:put, "http://s3.amazonaws.com/mybucket/object.txt")
               .with(body: "Hello")
               .to_return(body: "")

        client = Client.new("us-east-1", "key", "secret")
        client.put_object("mybucket", "object.txt", io)
      end
    end

    describe "list_objects" do
      it "handles pagination" do
        resp = <<-RESP
        <?xml version="1.0" encoding="UTF-8"?>
        <ListBucketResult xmlns="http://s3.amazonaws.com/doc/2006-03-01/">
          <Name>bucket</Name>
          <Prefix/>
          <KeyCount>1</KeyCount>
          <MaxKeys>1</MaxKeys>
          <IsTruncated>true</IsTruncated>
          <NextContinuationToken>token</NextContinuationToken
          <Contents>
              <Key>my-image.jpg</Key>
              <LastModified>2009-10-12T17:50:30.000Z</LastModified>
              <ETag>"fba9dede5f27731c9771645a39863328"</ETag>
              <Size>434234</Size>
              <StorageClass>STANDARD</StorageClass>
          </Contents>
        </ListBucketResult>
        RESP

        resp2 = <<-RESP
        <?xml version="1.0" encoding="UTF-8"?>
        <ListBucketResult xmlns="http://s3.amazonaws.com/doc/2006-03-01/">
          <Name>bucket</Name>
          <Prefix/>
          <KeyCount>1</KeyCount>
          <MaxKeys>1</MaxKeys>
          <IsTruncated>false</IsTruncated>
          <Contents>
              <Key>key2</Key>
              <LastModified>2009-10-12T17:50:30.000Z</LastModified>
              <ETag>"fba9dede5f27731c9771645a39863329"</ETag>
              <Size>1337</Size>
              <StorageClass>STANDARD</StorageClass>
          </Contents>
        </ListBucketResult>
        RESP

        WebMock.stub(:get, "http://s3.amazonaws.com/bucket?list-type=2&max-keys=1&continuation-token=token")
               .to_return(body: resp2)

        WebMock.stub(:get, "http://s3.amazonaws.com/bucket?list-type=2&max-keys=1")
               .to_return(body: resp)

        client = Client.new("us-east-1", "key", "secret")

        objects = [] of Array(Object)
        client.list_objects("bucket", max_keys: 1).each do |output|
          objects << output.contents
        end

        objects.flatten.should eq([
          Object.new("my-image.jpg", 434234,
            "\"fba9dede5f27731c9771645a39863328\""),
          Object.new("key2", 1337,
            "\"fba9dede5f27731c9771645a39863329\""),
        ])
      end

      it "supports basic case" do
        resp = <<-RESP
        <?xml version="1.0" encoding="UTF-8"?>
        <ListBucketResult xmlns="http://s3.amazonaws.com/doc/2006-03-01/">
          <Name>bucket</Name>
          <Prefix/>
          <KeyCount>205</KeyCount>
          <MaxKeys>1000</MaxKeys>
          <IsTruncated>false</IsTruncated>
          <Contents>
              <Key>my-image.jpg</Key>
              <LastModified>2009-10-12T17:50:30.000Z</LastModified>
              <ETag>&quot;fba9dede5f27731c9771645a39863328&quot;</ETag>
              <Size>434234</Size>
              <StorageClass>STANDARD</StorageClass>
          </Contents>
          <Contents>
              <Key>key2</Key>
              <LastModified>2009-10-12T17:50:30.000Z</LastModified>
              <ETag>&quot;fba9dede5f27731c9771645a39863329&quot;</ETag>
              <Size>1337</Size>
              <StorageClass>STANDARD</StorageClass>
          </Contents>
        </ListBucketResult>
        RESP

        WebMock.stub(:get, "http://s3.amazonaws.com/blah?list-type=2")
               .to_return(body: resp)

        client = Client.new("us-east-1", "key", "secret")

        objs = client.list_objects("blah").each do |output|
          output.contents.should eq([
            Object.new("my-image.jpg", 434234,
              "\"fba9dede5f27731c9771645a39863328\""),
            Object.new("key2", 1337,
              "\"fba9dede5f27731c9771645a39863329\""),
          ])
        end
      end
    end

    describe "list_buckets" do
      it "returns buckets on success" do
        resp = <<-RESP
        <?xml version="1.0" encoding="UTF-8"?>
        <ListAllMyBucketsResult xmlns="http://s3.amazonaws.com/doc/2006-03-01">
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

        WebMock.stub(:get, "http://s3.amazonaws.com/?")
               .to_return(body: resp)

        client = Client.new("us-east-1", "key", "secret")
        output = client.list_buckets

        output.buckets.should eq([Bucket.new("quotes", "2006-02-03T16:45:09.000Z")])
      end
    end

    describe "head_bucket" do
      it "raises if bucket does not exist" do
        WebMock.stub(:head, "http://s3.amazonaws.com/blah2?")
               .to_return(status: 404)

        client = Client.new("us-east-1", "key", "secret")

        expect_raises do
          client.head_bucket("blah2")
        end
      end

      it "returns true if bucket exists" do
        WebMock.stub(:head, "http://s3.amazonaws.com/blah?")
               .to_return(status: 200)

        client = Client.new("us-east-1", "key", "secret")
        result = client.head_bucket("blah")

        result.should be_true
      end
    end
  end
end
