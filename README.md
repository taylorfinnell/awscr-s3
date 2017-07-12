# awscr-s3

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
**Creating a `Presigned::Form`.**

```crystal
form = Awscr::S3::Presigned::Form.build("us-east-1", credentials) do |form|
  form.expiration(Time.epoch(Time.now.epoch + 1000))
  form.condition("bucket", BUCKET)
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

**Submitting the form via `HTTP::Client`.**

```crystal
form.submit(IO::Memory.new("Hello, S3!"))
```

**Creating a `Presigned::Url`.**

```crystal
options = Awscr::S3::Presigned::Url::Options.new(object: "test.txt", bucket: "mybucket", additional_options: {
  "Content-Type" => "image/png"
})

url = Awscr::S3::Presigned::Url.new(credentials, options)
url.for(:put)
```
 
[Examples](https://github.com/taylorfinnell/awscr-signer/tree/master/examples)

