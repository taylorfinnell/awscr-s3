require "../spec_helper"

module Awscr::S3
  describe XML do
    it "handle flattened" do
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

      xml = XML.new(resp)

      keys = [] of String
      xml.array("ListBucketResult/Contents") do |node|
        keys << node.string("Key")
      end

      keys.should eq(["my-image.jpg", "key2"])
    end

    it "is ok if not namespaced" do
      resp = <<-RESP
        <?xml version="1.0" encoding="UTF-8"?>
        <ListAllMyBucketsResult>
          <Buckets>
            <Bucket>
              <Name>samples</Name>
              <CreationDate>2006-02-03T16:41:58.000Z</CreationDate>
            </Bucket>
          </Buckets>
        </ListAllMyBucketsResult>
      RESP

      xml = XML.new(resp)
      xml.array("ListAllMyBucketsResult/Buckets/Bucket") do |node|
        node.string("Name").should eq("samples")
        node.should be_a(XML::NamespacedNode)
      end
    end

    it "handles namespacing" do
      resp = <<-RESP
        <?xml version="1.0" encoding="UTF-8"?>
        <ListAllMyBucketsResult xmlns="http://s3.amazonaws.com/doc/2006-03-01">
          <Buckets>
            <Bucket>
              <Name>samples</Name>
              <CreationDate>2006-02-03T16:41:58.000Z</CreationDate>
            </Bucket>
          </Buckets>
        </ListAllMyBucketsResult>
      RESP

      xml = XML.new(resp)
      xml.array("ListAllMyBucketsResult/Buckets/Bucket") do |node|
        node.should be_a(XML::NamespacedNode)
        node.string("Name").should eq("samples")
      end
    end
  end
end
