require "../../spec_helper"

module Awscr
  module S3
    module Presigned
      describe Url do
        it "allows signer versions" do
          Url::Options.new(
            region: "ap-northeast-1",
            aws_access_key: "AKIAIOSFODNN7EXAMPLE",
            aws_secret_key: "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY",
            bucket: "examplebucket",
            object: "/test.txt",
            signer: :v2
          )
        end

        it "uses region specific hosts" do
          options = Url::Options.new(
            region: "ap-northeast-1",
            aws_access_key: "AKIAIOSFODNN7EXAMPLE",
            aws_secret_key: "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY",
            bucket: "examplebucket",
            object: "/test.txt"
          )
          url = Url.new(options)

          url.for(:get).should match(/https:\/\/s3-#{options.region}.amazonaws.com/)
        end

        it "allows host override" do
          options = Url::Options.new(
            region: "us-east-1",
            aws_access_key: "AKIAIOSFODNN7EXAMPLE",
            aws_secret_key: "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY",
            bucket: "examplebucket",
            object: "/test.txt",
            host_name: "examplebucket.s3.amazonaws.com"
          )
          url = Url.new(options)

          url.for(:get).should match(/https:\/\/examplebucket.s3.amazonaws.com/)
        end

        it "raises on unsupported method" do
          options = Url::Options.new(
            region: "us-east-1",
            aws_access_key: "AKIAIOSFODNN7EXAMPLE",
            aws_secret_key: "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY",
            bucket: "examplebucket",
            object: "/test.txt"
          )
          url = Url.new(options)

          expect_raises(S3::Exception) do
            url.for(:test)
          end
        end

        describe "get" do
          it "generates correct url for v2" do
            time = Time.unix(1)
            Timecop.freeze(time)
            options = Url::Options.new(
              region: "us-east-1",
              aws_access_key: "AKIAIOSFODNN7EXAMPLE",
              aws_secret_key: "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY",
              bucket: "examplebucket",
              object: "/test.txt",
              signer: :v2
            )
            url = Url.new(options)

            url.for(:get)
              .should eq("https://s3.amazonaws.com/examplebucket/test.txt?Expires=86401&AWSAccessKeyId=AKIAIOSFODNN7EXAMPLE&Signature=KP7uBvqYauy%2Fzj1Rb9LgL7e87VY%3D")
          end

          it "generates a correct url for v4" do
            Timecop.freeze(Time.utc(2013, 5, 24)) do
              options = Url::Options.new(
                region: "us-east-1",
                aws_access_key: "AKIAIOSFODNN7EXAMPLE",
                aws_secret_key: "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY",
                bucket: "examplebucket",
                object: "/test.txt"
              )
              url = Url.new(options)

              url.for(:get)
                .should eq("https://s3.amazonaws.com/examplebucket/test.txt?X-Amz-Expires=86400&X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=AKIAIOSFODNN7EXAMPLE%2F20130524%2Fus-east-1%2Fs3%2Faws4_request&X-Amz-Date=20130524T000000Z&X-Amz-SignedHeaders=host&X-Amz-Signature=733255ef022bec3f2a8701cd61d4b371f3f28c9f193a1f02279211d48d5193d7")
            end
          end
        end
      end
    end
  end
end
