# awscr-s3
[![CircleCI](https://circleci.com/gh/taylorfinnell/awscr-s3.svg?style=svg)](https://circleci.com/gh/taylorfinnell/awscr-s3)

S3 access via Crystal

## Installation

Add this to your application's `shard.yml`:

```yaml
dependencies:
  awscr-s3:
    github: taylorfinnell/awscr-s3
```

## Usage

```crystal
require "awscr-s3"
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
[Examples](https://github.com/taylorfinnell/awscr-s3/tree/master/examples)

