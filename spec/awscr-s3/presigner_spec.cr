require "../spec_helper"

module Awscr::S3
  describe Presigner do
    describe "#presigned_form" do
      it "builds a form" do
        client = Client.new(
          region: "ap-northeast-1",
          aws_access_key: "AKIAIOSFODNN7EXAMPLE",
          aws_secret_key: "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY",
        )
        presigner = Presigner.new(client)
        form = presigner.presigned_form(bucket: "2") { }

        form.should be_a(Awscr::S3::Presigned::Form)
        form.fields.size.should eq 6 # bucket, and all the sig and policy stuff
      end

      it "generates an HTML form with mandatory fields" do
        client = Client.new(
          region: "ap-northeast-1",
          aws_access_key: "AKIAIOSFODNN7EXAMPLE",
          aws_secret_key: "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY",
        )
        presigner = Presigner.new(client)
        form = presigner.presigned_form(
          bucket: "examplebucket",
          key: "hello.txt",
          acl: "public-read",
          content_type: "text/plain",
          success_action_status: "201"
        )

        html = form.to_html.to_s
        html.should match(/name="key" value="hello\.txt"/)
        html.should match(/name="acl" value="public-read"/)
        html.should match(/name="Content-Type" value="text\/plain"/)
        html.should match(/name="success_action_status" value="201"/)
        html.should match(/<form action="http:\/\/examplebucket\.s3\.amazonaws\.com"/)
      end

      it "propagates arbitrary extra conditions" do
        client = Client.new(
          region: "ap-northeast-1",
          aws_access_key: "AKIAIOSFODNN7EXAMPLE",
          aws_secret_key: "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY",
        )
        presigner = Presigner.new(client)
        form = presigner.presigned_form(
          bucket: "examplebucket",
          key: "hello.txt",
          conditions: {"x-id" => "PutObject"}
        )
        fields = form.fields.map(&.key)
        fields.should contain("x-id")
      end

      it "raises if expires exceeds 7 days" do
        client = Client.new(
          region: "ap-northeast-1",
          aws_access_key: "AKIAIOSFODNN7EXAMPLE",
          aws_secret_key: "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY",
        )
        presigner = Presigner.new(client)
        expect_raises(ArgumentError) do
          presigner.presigned_form(
            bucket: "examplebucket",
            key: "hello.txt",
            expires: 700_000
          )
        end
      end

      it "yields the policy object so callers can add conditions" do
        client = Client.new(
          region: "ap-northeast-1",
          aws_access_key: "AKIAIOSFODNN7EXAMPLE",
          aws_secret_key: "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY",
        )
        presigner = Presigner.new(client)
        form = presigner.presigned_form(
          bucket: "examplebucket",
          key: "hello.txt"
        ) do |policy|
          policy.condition("x-id", "PutObject")
        end

        field_keys = form.fields.map(&.key)
        field_keys.should contain("x-id")
      end

      it "still honours top-level keyword args when a block is given" do
        client = Client.new(
          region: "ap-northeast-1",
          aws_access_key: "AKIAIOSFODNN7EXAMPLE",
          aws_secret_key: "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY",
        )
        presigner = Presigner.new(client)
        form = presigner.presigned_form(
          bucket: "examplebucket",
          key: "hello.txt",
          content_type: "text/plain"
        ) { }

        form.to_html.to_s.should match(/name="Content-Type" value="text\/plain"/)
      end
    end

    describe "#presigned_url" do
      it "allows signer versions" do
        client = Client.new(
          region: "ap-northeast-1",
          aws_access_key: "AKIAIOSFODNN7EXAMPLE",
          aws_secret_key: "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY",
        )
        presigner = Presigner.new(client)

        presigner.presigned_url("examplebucket", "/test.txt", signer: :v2)
      end

      it "uses region specific hosts" do
        client = Client.new(
          region: "ap-northeast-1",
          aws_access_key: "AKIAIOSFODNN7EXAMPLE",
          aws_secret_key: "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY",
        )
        presigner = Presigner.new(client)

        presigned_url = presigner.presigned_url("examplebucket", "/test.txt")

        presigned_url.should match(/https:\/\/examplebucket\.s3-#{client.region}.amazonaws.com\/test.txt/)
      end

      it "raises on unsupported method" do
        client = Client.new(
          region: "ap-northeast-1",
          aws_access_key: "AKIAIOSFODNN7EXAMPLE",
          aws_secret_key: "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY",
        )
        presigner = Presigner.new(client)

        expect_raises(S3::Exception) do
          presigner.presigned_url("examplebucket", "/test.txt", method: :test)
        end
      end

      describe "get" do
        it "generates correct url for v2" do
          time = Time.unix(1)
          Timecop.freeze(time)

          client = Client.new(
            region: "us-east-1",
            aws_access_key: "AKIAIOSFODNN7EXAMPLE",
            aws_secret_key: "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY",
          )
          presigner = Presigner.new(client)

          presigned_url = presigner.presigned_url("examplebucket", "/test.txt", signer: :v2)

          presigned_url
            .should eq("https://examplebucket.s3.amazonaws.com/test.txt?Expires=86401&AWSAccessKeyId=AKIAIOSFODNN7EXAMPLE&Signature=KP7uBvqYauy%2Fzj1Rb9LgL7e87VY%3D")
        end

        it "generates a correct url for v4" do
          Timecop.freeze(Time.utc(2013, 5, 24)) do
            client = Client.new(
              region: "us-east-1",
              aws_access_key: "AKIAIOSFODNN7EXAMPLE",
              aws_secret_key: "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY",
            )
            presigner = Presigner.new(client)

            presigned_url = presigner.presigned_url("examplebucket", "/test.txt")

            presigned_url
              .should eq("https://examplebucket.s3.amazonaws.com/test.txt?X-Amz-Expires=86400&X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=AKIAIOSFODNN7EXAMPLE%2F20130524%2Fus-east-1%2Fs3%2Faws4_request&X-Amz-Date=20130524T000000Z&X-Amz-SignedHeaders=host&X-Amz-Signature=aeeed9bbccd4d02ee5c0109b86d86835f995330da4c265957d157751f604d404")
          end
        end

        it "inserts each option as a query param for v4" do
          Timecop.freeze(Time.utc(2013, 5, 24)) do
            client = Client.new(
              region: "us-east-1",
              aws_access_key: "AKIAIOSFODNN7EXAMPLE",
              aws_secret_key: "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY",
            )
            presigner = Presigner.new(client)

            url = presigner.presigned_url(
              "examplebucket",
              "/test.txt",
              response_content_type: "text/plain",
              x_id: "GetObject",
            )

            url.should match(/response-content-type=text%2Fplain/) # URL-encoded '/'
            url.should match(/x-id=GetObject/)
            url.should match(/X-Amz-Signature=[0-9a-f]{64}/)
          end
        end

        it "additional_options has the same query params as kwargs" do
          Timecop.freeze(Time.utc(2013, 5, 24)) do
            client = Client.new(
              region: "us-east-1",
              aws_access_key: "AKIAIOSFODNN7EXAMPLE",
              aws_secret_key: "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY",
            )
            presigner = Presigner.new(client)

            kwargs_urls = presigner.presigned_url(
              "examplebucket",
              "/test.txt",
              foo: "bar",
              baz: "qux",
            )
            additional_options_url = presigner.presigned_url(
              "examplebucket",
              "/test.txt",
              additional_options: {
                "baz" => "qux",
                "foo" => "bar",
              }
            )

            kwargs_urls.should match(/foo=bar/)
            additional_options_url.should match(/foo=bar/)

            kwargs_urls.should match(/baz=qux/)
            additional_options_url.should match(/baz=qux/)
          end
        end

        it "with force_path_style" do
          Timecop.freeze(Time.utc(2013, 5, 24)) do
            client = Client.new(
              region: "unused",
              endpoint: "http://127.0.0.1:9000",
              aws_access_key: "AKIAIOSFODNN7EXAMPLE",
              aws_secret_key: "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY",
            )
            presigner = Presigner.new(client)

            presigned_url = presigner.presigned_url("examplebucket", "/test.txt", force_path_style: true)

            presigned_url
              .should eq("http://127.0.0.1:9000/examplebucket/test.txt?X-Amz-Expires=86400&X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=AKIAIOSFODNN7EXAMPLE%2F20130524%2Funused%2Fs3%2Faws4_request&X-Amz-Date=20130524T000000Z&X-Amz-SignedHeaders=host&X-Amz-Signature=c4a84832797f4186a789b297af55d2c014cd687933995d72247ed339496d878f")
          end
        end
      end
    end
  end
end
