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
          it "sends a reasonable request over http" do
            post = Post.new(
              region: "us-east-1",
              aws_access_key: "test",
              aws_secret_key: "test"
            )
            time = Time.epoch(1)

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

            client = HTTP::Client.new("fake host")
            io = IO::Memory.new("test")
            form = Form.new(post, client)
            resp = form.submit(io)
          end
        end
      end
    end
  end
end
