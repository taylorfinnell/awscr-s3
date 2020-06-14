require "../../spec_helper"

module Awscr
  module S3
    module Presigned
      describe HtmlPrinter do
        Spec.before_each do
          Timecop.freeze(Time.unix(1))
        end

        Spec.after_each do
          Timecop.return
        end

        it "generates the same html each call" do
          time = Time.unix(1)
          post = Post.new(
            region: "us-east-1",
            aws_access_key: "test",
            aws_secret_key: "test"
          )

          post.build do |b|
            b.expiration(time)
            b.condition("bucket", "test")
          end
          form = Form.new(post, HTTP::Client.new(""))

          printer = HtmlPrinter.new(form)

          printer.print.should eq(printer.print)
        end

        it "prints html" do
          time = Time.unix(1)

          post = Post.new(
            region: "region",
            aws_access_key: "test",
            aws_secret_key: "test"
          )

          post.build do |b|
            b.expiration(time)
            b.condition("bucket", "test")
          end
          form = Form.new(post, HTTP::Client.new(""))

          printer = HtmlPrinter.new(form)

          html = <<-HTML
          <form action="http://test.s3.amazonaws.com" method="post" enctype="multipart/form-data">
            <input type="hidden" name="bucket" value="test" /><br />
            <input type="hidden" name="x-amz-credential" value="test/19700101/region/s3/aws4_request" /><br />
            <input type="hidden" name="x-amz-algorithm" value="AWS4-HMAC-SHA256" /><br />
            <input type="hidden" name="x-amz-date" value="19700101T000001Z" /><br />
            <input type="hidden" name="policy" value="eyJleHBpcmF0aW9uIjoiMTk3MC0wMS0wMVQwMDowMDowMS4wMDBaIiwiY29uZGl0aW9ucyI6W3siYnVja2V0IjoidGVzdCJ9LHsieC1hbXotY3JlZGVudGlhbCI6InRlc3QvMTk3MDAxMDEvcmVnaW9uL3MzL2F3czRfcmVxdWVzdCJ9LHsieC1hbXotYWxnb3JpdGhtIjoiQVdTNC1ITUFDLVNIQTI1NiJ9LHsieC1hbXotZGF0ZSI6IjE5NzAwMTAxVDAwMDAwMVoifV19" /><br />
            <input type="hidden" name="x-amz-signature" value="f509df9965f9cf92b77aabc6b81a6f2fd24f36d3a6daaf46e9704ef5c333ee88" />

            <input type="file"   name="file" /> <br />
            <input type="submit" name="submit" value="Upload" />
          </form>
          HTML

          printer.print.gsub("\n", "").gsub(" ", "").should eq(html.gsub("\n", "").gsub(" ", ""))
        end
      end
    end
  end
end
