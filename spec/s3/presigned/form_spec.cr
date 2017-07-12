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
            creds = Signer::Credentials.new("test", "test")
            form = Form.build("us-east-1", creds) do |f|
              f.condition("bucket", "2")
            end

            form.should be_a(Form)
            form.fields.size.should eq 6 # bucket, and all the sig and policy stuff
          end
        end

        describe "fields" do
          it "is a field collection" do
            creds = Signer::Credentials.new("test", "test")
            post = Post.new("us-east-1", creds)
            form = Form.new(post, HTTP::Client.new(""))

            form.fields.should be_a(FieldCollection)
          end
        end

        describe "to_html" do
          it "returns an html printer" do
            creds = Signer::Credentials.new("test", "test")
            post = Post.new("us-east-1", creds)
            form = Form.new(post, HTTP::Client.new(""))

            form.to_html.should be_a(HtmlPrinter)
          end
        end

        describe "submit" do
          it "sends a reasonable request over http" do
            creds = Signer::Credentials.new("test", "test")
            post = Presigned::Post.new("us-east-1", creds)
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
