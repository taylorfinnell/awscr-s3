require "../spec_helper"
require "http/client"

describe "minio flow", tags: "integration" do
  client = Awscr::S3::Client.new(
    region: "unused",
    aws_access_key: ENV.fetch("S3_KEY", "admin"),
    aws_secret_key: ENV.fetch("S3_SECRET", "password"),
    endpoint: ENV.fetch("S3_ENDPOINT", "http://127.0.0.1:9000")
  )
  bucket_name = "awscr-s3-test-#{UUID.random}"

  before_all do
    cleanup_buckets(client)
    client.put_bucket(bucket_name)
  end

  after_all do
    cleanup_buckets(client)
  end

  it "lists buckets" do
    actual = client.list_buckets
    actual.should_not eq(nil)
  end

  it "creates a bucket" do
    name = bucket_name + "createbucket"
    actual = client.put_bucket(name)
    actual.should_not eq(nil)

    list_buckets = client.list_buckets.buckets.map(&.name)
    list_buckets.should contain(name)
  end

  it "deletes a bucket" do
    client.put_bucket("awcr-s3-test-deletes-bucket")
    response = client.delete_bucket("awcr-s3-test-deletes-bucket")
    response.should eq(true)
  end

  it "creates an object and reads it" do
    key = "foo"
    body = "Content of the Key"
    actual = client.put_object(bucket_name, key, body)
    actual.etag.should_not eq(nil)

    response = client.head_object(bucket_name, key)
    response.meta.should be_empty

    response = client.get_object(bucket_name, key)
    response.body.should eq(body)
  end

  it "lists objects" do
    client.put_object(bucket_name, "list_obj_a", "")
    client.put_object(bucket_name, "list_obj_b", "")

    actual = [] of String
    client.list_objects(bucket_name).each do |resp|
      actual += resp.contents.map(&.key)
    end
    actual.should contain("list_obj_a")
    actual.should contain("list_obj_b")

    response = client.batch_delete(bucket_name, ["list_obj_a", "list_obj_b"])
    response.success?.should eq(true)
  end

  it "download object with presigned url" do
    begin
      client.put_bucket(bucket_name)
    rescue Awscr::S3::BucketAlreadyOwnedByYou
    end
    object = "/#{UUID.random}"

    response = client.put_object(bucket_name, object, "Howdy")
    response.etag.should_not eq(nil)

    options = Awscr::S3::Presigned::Url::Options.new(
      aws_access_key: ENV.fetch("S3_KEY", "admin"),
      aws_secret_key: ENV.fetch("S3_SECRET", "password"),
      region: "unused",
      endpoint: ENV.fetch("S3_ENDPOINT", "http://127.0.0.1:9000"),
      bucket: bucket_name,
      force_path_style: true,
      object: object
    )

    url = Awscr::S3::Presigned::Url.new(options).for(:get)
    url.should contain("http://127.0.0.1:9000/#{bucket_name}#{object}")

    HTTP::Client.get(url) do |resp|
      resp.status_code.should eq(200)
      resp.body_io.gets.should eq("Howdy")
    end
  end
end

def cleanup_buckets(client)
  WebMock.allow_net_connect = true

  list_buckets = client.list_buckets.buckets.map(&.name)
  list_buckets.each do |bucket|
    next if !bucket.starts_with?("awscr-s3-test-")
    objects = [] of String
    client.list_objects(bucket).each do |resp|
      objects += resp.contents.map(&.key)
    end
    client.batch_delete(bucket, objects) if objects.size > 0
    client.delete_bucket(bucket)
  end
end
