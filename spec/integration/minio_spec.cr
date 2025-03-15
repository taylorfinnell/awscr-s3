require "../spec_helper"

describe "minio flow", tags: "integration" do
  client = Awscr::S3::Client.new(
    region: "unused",
    aws_access_key: ENV.fetch("S3_KEY", "admin"),
    aws_secret_key: ENV.fetch("S3_SECRET", "password"),
    endpoint: ENV.fetch("S3_ENDPOINT", "http://127.0.0.1:9000")
  )

  it "lists buckets" do
    actual = client.list_buckets
    actual.should_not eq(nil)
  end
end
