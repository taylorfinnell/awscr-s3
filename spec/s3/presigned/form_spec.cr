require "../../spec_helper"

module Awscr
  module S3
    module Presigned
      class FakeClient < HTTP::Client
        @last_request_path : String?
        @last_request_headers : HTTP::Headers?
        @last_request_body : String?

        getter last_request_path
        getter last_request_headers
        getter last_request_body

        def post(path, headers, body)
          @last_request_path = path
          @last_request_headers = headers
          @last_request_body = body
        end
      end

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
            form = Form.new(post, FakeClient.new("host"))

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
            form = Form.new(post, FakeClient.new("host"))

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

            client = FakeClient.new("fake host")
            io = IO::Memory.new("test")
            form = Form.new(post, client)
            resp = form.submit(io)

            client.last_request_path.should eq "/"

            headers = client.last_request_headers
            headers.not_nil!["Content-Type"].nil?.should eq false

            client.last_request_body.nil?.should eq false
          end
        end
      end
    end
  end
end
