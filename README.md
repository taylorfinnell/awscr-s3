# awscr-s3
[![CircleCI](https://circleci.com/gh/taylorfinnell/awscr-s3.svg?style=svg)](https://circleci.com/gh/taylorfinnell/awscr-s3)

A Crystal shard for S3.

## Installation

Add this to your application's `shard.yml`:

```yaml
dependencies:
  awscr-s3:
    github: taylorfinnell/awscr-s3
```

## Examples

[Examples](https://github.com/taylorfinnell/awscr-s3/tree/master/examples)

## Usage

```crystal
require "awscr-s3"
```

## **Creating a Client**

```crystal
client = Awscr::S3::Client.new("us-east1", "key", "secret")
```
## **List Buckets**

```crystal
resp = client.list_buckets
resp.buckets # => ["bucket1", "bucket2"]
```

## **Put Object**

```crystal
resp = client.put_object("bucket_name", "object_key", "myobjectbody")
resp.etag # => ...
```

## **Get Object**

```crystal
resp = client.put_object("bucket_name", "object_key")
resp.body # => myobjectbody
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

## **Creating a `Presigned::Form`.**

```crystal
form = Awscr::S3::Presigned::Form.build("us-east-1", "access key", "secret key") do |form|
  form.expiration(Time.epoch(Time.now.epoch + 1000))
  form.condition("bucket", "mybucket")
  form.condition("acl", "public-read")
  form.condition("key", SecureRandom.uuid)
  form.condition("Content-Type", "text/plain")
  form.condition("success_action_status", "201")
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
p url.for(:put)
```
