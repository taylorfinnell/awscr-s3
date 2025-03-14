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

          url.for(:get).should match(/https:\/\/examplebucket\.s3-#{options.region}.amazonaws.com\/test.txt/)
        end

        it "allows host override" do
          options = Url::Options.new(
            region: "us-east-1",
            aws_access_key: "AKIAIOSFODNN7EXAMPLE",
            aws_secret_key: "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY",
            bucket: "examplebucket",
            object: "/test.txt",
            host_name: "example.com"
          )
          url = Url.new(options)

          url.for(:get).should match(/https:\/\/examplebucket.example.com\/test.txt/)
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
              .should eq("https://examplebucket.s3.amazonaws.com/test.txt?Expires=86401&AWSAccessKeyId=AKIAIOSFODNN7EXAMPLE&Signature=KP7uBvqYauy%2Fzj1Rb9LgL7e87VY%3D")
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
                .should eq("https://examplebucket.s3.amazonaws.com/test.txt?X-Amz-Expires=86400&X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=AKIAIOSFODNN7EXAMPLE%2F20130524%2Fus-east-1%2Fs3%2Faws4_request&X-Amz-Date=20130524T000000Z&X-Amz-SignedHeaders=host&X-Amz-Signature=aeeed9bbccd4d02ee5c0109b86d86835f995330da4c265957d157751f604d404")
            end
          end

          it "override default endpoint" do
            Timecop.freeze(Time.utc(2013, 5, 24)) do
              options = Url::Options.new(
                endpoint: "http://127.0.0.1:9000",
                region: "unused",
                aws_access_key: "AKIAIOSFODNN7EXAMPLE",
                aws_secret_key: "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY",
                bucket: "examplebucket",
                object: "/test.txt"
              )
              url = Url.new(options)

              url.for(:get)
                .should eq("http://examplebucket.127.0.0.1:9000/test.txt?X-Amz-Expires=86400&X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=AKIAIOSFODNN7EXAMPLE%2F20130524%2Funused%2Fs3%2Faws4_request&X-Amz-Date=20130524T000000Z&X-Amz-SignedHeaders=host&X-Amz-Signature=4cd2d055e88b21dc0fa9027338aa1e2a1a90a88b61124edd7b9fae6299efcea4")
            end
          end

          it "with force_path_style" do
            Timecop.freeze(Time.utc(2013, 5, 24)) do
              options = Url::Options.new(
                host_name: "127.0.0.1:9000",
                scheme: "http",
                region: "unused",
                aws_access_key: "AKIAIOSFODNN7EXAMPLE",
                aws_secret_key: "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY",
                bucket: "examplebucket",
                force_path_style: true,
                object: "/test.txt"
              )
              url = Url.new(options)

              url.for(:get)
                .should eq("http://127.0.0.1:9000/examplebucket/test.txt?X-Amz-Expires=86400&X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=AKIAIOSFODNN7EXAMPLE%2F20130524%2Funused%2Fs3%2Faws4_request&X-Amz-Date=20130524T000000Z&X-Amz-SignedHeaders=host&X-Amz-Signature=c4a84832797f4186a789b297af55d2c014cd687933995d72247ed339496d878f")
            end
          end
        end
      end
    end
  end
end
