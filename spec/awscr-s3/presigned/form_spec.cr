require "../../spec_helper"

module Awscr
  module S3
    module Presigned
      describe Form do
        describe ".build" do
          it "builds a form" do
            form = Form.build(
              region: "us-east-1",
              aws_access_key: "test",
              aws_secret_key: "test") do |f|
              f.condition("bucket", "2")
            end

            form.should be_a(Form)
            form.fields.size.should eq 6 # bucket, and all the sig and policy stuff
          end
        end

        describe "url" do
          it "returns form url" do
            form = Form.build(
              region: "us-east-1",
              aws_access_key: "test",
              aws_secret_key: "test") do |f|
              f.condition("bucket", "hi")
            end

            form.url.should eq("http://hi.s3.amazonaws.com")
          end
        end

        describe "fields" do
          it "is a field collection" do
            post = Post.new(
              region: "us-east-1",
              aws_access_key: "test",
              aws_secret_key: "test"
            )
            form = Form.new(post, HTTP::Client.new("host"))

            form.fields.should be_a(FieldCollection)
          end
        end

        describe "to_html" do
          it "returns an html printer" do
            post = Post.new(
              region: "us-east-1",
              aws_access_key: "test",
              aws_secret_key: "test"
            )
            form = Form.new(post, HTTP::Client.new("host"))

            form.to_html.should be_a(HtmlPrinter)
          end
        end

        describe "submit" do
          it "sends a reasonable request over http for v2" do
            time = Time.unix(1)
            Timecop.freeze(time)

            post = Post.new(
              region: "us-east-1",
              aws_access_key: "test",
              aws_secret_key: "test",
              signer: :v2
            )

            post.build do |builder|
              builder.expiration(time)
              builder.condition("bucket", "test")
              builder.condition("key", "hi")
            end

            WebMock.stub(:post, "http://fake host/").to_return do |request|
              request.headers.not_nil!["Content-Type"].nil?.should eq false
              request.body.nil?.should eq false

              HTTP::Client::Response.new(200, body: "")
            end

            post.fields["Signature"].should eq("2OuTzB6hWfTJsU6UuN4mLuVEHpY=")

            client = HTTP::Client.new("fake host")
            io = IO::Memory.new("test")
            form = Form.new(post, client)
            form.submit(io)
          end

          it "sends a reasonable request over http for v4" do
            time = Time.unix(1)
            Timecop.freeze(time)

            post = Post.new(
              region: "us-east-1",
              aws_access_key: "test",
              aws_secret_key: "test"
            )

            post.build do |builder|
              builder.expiration(time)
              builder.condition("bucket", "test")
              builder.condition("key", "hi")
            end

            WebMock.stub(:post, "http://fake host/").to_return do |request|
              request.headers.not_nil!["Content-Type"].nil?.should eq false
              request.body.nil?.should eq false

              HTTP::Client::Response.new(200, body: "")
            end

            post.fields["X-Amz-Signature"].should eq("db2a7f49b8c2b1513db3f85416ea04d38cb4a55b39f6c4a56b0bd83b41594a3d")

            client = HTTP::Client.new("fake host")
            io = IO::Memory.new("test")
            form = Form.new(post, client)
            form.submit(io)
          end
        end
      end
    end
  end
end
