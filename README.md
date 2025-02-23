# awscr-s3

[![CI](https://github.com/taylorfinnell/awscr-s3/actions/workflows/ci.yml/badge.svg)](https://github.com/taylorfinnell/awscr-s3/actions/workflows/ci.yml)

A Crystal shard for S3 and compatible services.

## Installation

Add this to your application's `shard.yml`:

```yaml
dependencies:
  awscr-s3:
    github: taylorfinnell/awscr-s3
```

## Examples

[Examples](https://github.com/taylorfinnell/awscr-s3/tree/master/examples)

## Documentation

[Documentation](https://taylorfinnell.github.io/awscr-s3/)

## Usage

```crystal
require "awscr-s3"
```

## **Creating a Client**

```crystal
client = Awscr::S3::Client.new("us-east-1", "key", "secret")
```

For S3 compatible services, like DigitalOcean Spaces or Minio, you'll need to set a custom endpoint:

```crystal
client = Awscr::S3::Client.new("nyc3", "key", "secret", endpoint: "https://nyc3.digitaloceanspaces.com")
```

If you wish you wish to you version 2 request signing you may specify the signer

```crystal
client = Awscr::S3::Client.new("us-east-1", "key", "secret", signer: :v2)
```

## **List Buckets**

```crystal
resp = client.list_buckets
resp.buckets # => ["bucket1", "bucket2"]
```

## **Delete a bucket**

```crystal
client = Client.new("region", "key", "secret")
resp = client.delete_bucket("test")
resp # => true
```

## Create a bucket

```crystal
client = Client.new("region", "key", "secret")
resp = client.put_bucket("test")
resp # => true
```

## **Put Object**

```crystal
resp = client.put_object("bucket_name", "object_key", "myobjectbody")
resp.etag # => ...
```

You can also pass additional headers (e.g. metadata):

```crystal
client.put_object("bucket_name", "object_key", "myobjectbody", {"x-amz-meta-name" => "myobject"})
```

## **Delete Object**

```crystal
resp = client.delete_object("bucket_name", "object_key")
resp # => true
```

## **Check Bucket Existence**

```crystal
resp = client.head_bucket("bucket_name")
resp # => true
```

Raises an exception if bucket does not exist.

## **Batch Delete Objects**

```crystal
resp = client.batch_delete("bucket_name", ["key1", "key2"])
resp.success? # => true
```

## **Get Object**

```crystal
resp = client.get_object("bucket_name", "object_key")
resp.body # => myobjectbody

# Or stream the object (recommended for large objects)
client.get_object("bucket_name", "object_key") do |obj|
  IO.copy(obj.body_io, STDOUT) # => myobjectbody
end
```

## **List Objects**

```crystal
client.list_objects("bucket_name").each do |resp|
  p resp.contents.map(&.key)
end
```

## **Upload a file**

```crystal
uploader = Awscr::S3::FileUploader.new(client)

File.open(File.expand_path("myfile"), "r") do |file|
  puts uploader.upload("bucket_name", "someobjectkey", file)
end
```

You can also pass additional headers (e.g. metadata):

```crystal
uploader = Awscr::S3::FileUploader.new(client)

File.open(File.expand_path("myfile"), "r") do |file|
  puts uploader.upload("bucket_name", "someobjectkey", file, {"x-amz-meta-name" => "myobject"})
end
```

## **Creating a `Presigned::Form`.**

```crystal
form = Awscr::S3::Presigned::Form.build("us-east-1", "access key", "secret key") do |form|
  form.expiration(Time.unix(Time.now.to_unix + 1000))
  form.condition("bucket", "mybucket")
  form.condition("acl", "public-read")
  form.condition("key", SecureRandom.uuid)
  form.condition("Content-Type", "text/plain")
  form.condition("success_action_status", "201")
end
```

You may use version 2 request signing via

```crystal
form = Awscr::S3::Presigned::Form.build("us-east-1", "access key", "secret key", signer: :v2) do |form|
  ...
end
```

**Converting the form to raw HTML (for browser uploads, etc).**

```crystal
puts form.to_html
```

**Submitting the form.**

```crystal
data = IO::Memory.new("Hello, S3!")
form.submit(data)
```

## **Creating a `Presigned::Url`.**

```crystal
options = Awscr::S3::Presigned::Url::Options.new(
   aws_access_key: "key",
   aws_secret_key: "secret",
   region: "us-east-1",
   object: "test.txt",
   bucket: "mybucket",
   additional_options: {
  "Content-Type" => "image/png"
})

url = Awscr::S3::Presigned::Url.new(options)
puts url.for(:put)
```

You may use version 2 request signing via

```crystal
options = Awscr::S3::Presigned::Url::Options.new(
  aws_access_key: "key",
  aws_secret_key: "secret",
  region: "us-east-1",
  object: "test.txt",
  bucket: "mybucket",
  signer: :v2
)
```

### Support 3rd party services

For S3-compatible services like DigitalOcean Spaces, Minio, or Backblaze B2, you'll need to set a custom endpoint.

**Minio (local)**

To use Minio locally, ensure your Minio server is running and configure the endpoint as follows:

```crystal
options = Awscr::S3::Presigned::Url::Options.new(
  endpoint: "http://127.0.0.1:9000",
  region: "unused",
  aws_access_key: "admin",
  aws_secret_key: "password",
  bucket: "foo",
  force_path_style: true,
  object: "/test.txt"
)

url = Awscr::S3::Presigned::Url.new(options)
puts url.for(:get) # => "http://127.0.0.1:9000/foo/test.txt?X-Amz-Expires=86400&X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=admin%2F20250313%2Funused%2Fs3%2Faws4_request&X-Amz-Date=20250313T235624Z&X-Amz-SignedHeaders=host&X-Amz-Signature=ce2b33af1dbfd0e132f31d3f9d716eb5d66f4d19fbdcb691e816f7033e345bce"
```

**DigitalOcean Spaces**

For DigitalOcean Spaces, the bucket is included in the subdomain:

```crystal
options = Awscr::S3::Presigned::Url::Options.new(
  endpoint: "https://ams3.digitaloceanspaces.com",
  region: "unused",
  aws_access_key: "ACCESSKEYEXAMPLE",
  aws_secret_key: "SECRETKEYEXAMPLE",
  bucket: "foo",
  object: "/test.txt"
)

url = Awscr::S3::Presigned::Url.new(options)
puts url.for(:get) # => "https://foo.ams3.digitaloceanspaces.com/test.txt?X-Amz-Expires=86400&X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=ACCESSKEYEXAMPLE%2F20250313%2Funused%2Fs3%2Faws4_request&X-Amz-Date=20250313T235511Z&X-Amz-SignedHeaders=host&X-Amz-Signature=e7b17f3c335ed615bf68845f81c2091814f856b61d05cb5aae3ad664de0f1b6e"
```
