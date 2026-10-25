require "../spec_helper"

module Awscr::S3
  SIGNER = Awscr::Signer::Signers::V4.new("blah", "blah", "blah", "blah")

  ERROR_BODY = <<-BODY
    <?xml version="1.0" encoding="UTF-8"?>
    <Error>
      <Code>NoSuchKey</Code>
      <Message>The resource you requested does not exist</Message>
      <Resource>/mybucket/myfoto.jpg</Resource>
      <RequestId>4442587FB7D0A2F9</RequestId>
    </Error>
    BODY

  describe Http do
    describe "initialize" do
      it "sets the correct endpoint" do
        WebMock.stub(:get, "https://s3.amazonaws.com/")
          .to_return(status: 200)

        client = Client.new("us-east-1", "some_access_key", "some_secret_key")

        http = Http.new(SIGNER, client.endpoint)

        http.get("/").status_code.should eq 200
      end

      it "sets the correct endpoint with a defined region" do
        WebMock.stub(:get, "https://s3-eu-west-1.amazonaws.com/")
          .to_return(status: 200)

        client = Client.new("eu-west-1", "some_access_key", "some_secret_key")
        http = Http.new(SIGNER, client.endpoint)

        http.get("/").status_code.should eq 200
      end

      it "can set a custom endpoint" do
        WebMock.stub(:get, "https://nyc3.digitaloceanspaces.com")
          .to_return(status: 200)

        client = Client.new("us-east-1", "some_access_key", "some_secret_key", endpoint: "https://nyc3.digitaloceanspaces.com")

        http = Http.new(SIGNER, client.endpoint)

        http.get("/").status_code.should eq 200
      end

      it "can set a custom endpoint with a port" do
        WebMock.stub(:get, "http://127.0.0.1:9000")
          .to_return(status: 200)

        client = Client.new("us-east-1", "some_access_key", "some_secret_key", endpoint: "http://127.0.0.1:9000")

        http = Http.new(SIGNER, client.endpoint)

        http.get("/").status_code.should eq 200
      end
    end

    describe "client_factory" do
      it "calls `#acquire_client` and `#release` for each request" do
        factory = HttpClientFactoryMock.new
        http = Http.new(SIGNER, URI.parse("https://s3.amazonaws.com"), factory)

        WebMock.stub(:get, "https://s3.amazonaws.com/path").to_return(status: 200)

        http.get("/path")

        factory.acquired_count.should eq(1)
        factory.released_count.should eq(1)
      end
    end

    describe "get" do
      it "handles aws specific errors" do
        WebMock.stub(:get, "https://s3.amazonaws.com/sup?")
          .to_return(status: 404, body: ERROR_BODY)

        client = Client.new("us-east-1", "some_access_key", "some_secret_key")

        http = Http.new(SIGNER, client.endpoint)

        expect_raises S3::NoSuchKey, "The resource you requested does not exist" do
          http.get("/sup")
        end
      end

      it "handles bad responses" do
        WebMock.stub(:get, "https://s3.amazonaws.com/sup?")
          .to_return(status: 404)

        client = Client.new("us-east-1", "some_access_key", "some_secret_key")

        http = Http.new(SIGNER, client.endpoint)

        expect_raises S3::Exception do
          http.get("/sup")
        end
      end

      context "with body_io" do
        it "handles aws specific errors" do
          WebMock.stub(:get, "https://s3.amazonaws.com/sup?")
            .to_return(status: 404, body: ERROR_BODY)

          client = Client.new("us-east-1", "some_access_key", "some_secret_key")

          http = Http.new(SIGNER, client.endpoint)

          expect_raises S3::NoSuchKey, "The resource you requested does not exist" do
            http.get("/sup")
          end
        end

        it "handles bad responses" do
          WebMock.stub(:get, "https://s3.amazonaws.com/sup?")
            .to_return(status: 404)

          client = Client.new("us-east-1", "some_access_key", "some_secret_key")

          http = Http.new(SIGNER, client.endpoint)

          expect_raises S3::Exception do
            http.get("/sup")
          end
        end
      end
    end

    describe "head" do
      it "handles aws specific errors" do
        WebMock.stub(:head, "https://s3.amazonaws.com/?")
          .to_return(status: 404, body: ERROR_BODY)

        client = Client.new("us-east-1", "some_access_key", "some_secret_key")

        http = Http.new(SIGNER, client.endpoint)

        expect_raises S3::Exception, "The resource you requested does not exist" do
          http.head("/")
        end
      end

      it "handles bad responses" do
        WebMock.stub(:head, "https://s3.amazonaws.com/?")
          .to_return(status: 404)

        client = Client.new("us-east-1", "some_access_key", "some_secret_key")

        http = Http.new(SIGNER, client.endpoint)

        expect_raises S3::Exception do
          http.head("/")
        end
      end
    end

    describe "put" do
      it "handles aws specific errors" do
        WebMock.stub(:put, "https://s3.amazonaws.com/?")
          .to_return(status: 404, body: ERROR_BODY)

        client = Client.new("us-east-1", "some_access_key", "some_secret_key")

        http = Http.new(SIGNER, client.endpoint)

        expect_raises S3::NoSuchKey, "The resource you requested does not exist" do
          http.put("/", "")
        end
      end

      it "handles bad responses" do
        WebMock.stub(:put, "https://s3.amazonaws.com/?")
          .to_return(status: 404)

        client = Client.new("us-east-1", "some_access_key", "some_secret_key")

        http = Http.new(SIGNER, client.endpoint)

        expect_raises S3::Exception do
          http.put("/", "")
        end
      end

      it "sets the Content-Length header by default" do
        WebMock.stub(:put, "https://s3.amazonaws.com/document")
          .with(body: "abcd", headers: {"Content-Length" => "4"})
          .to_return(status: 200)

        client = Client.new("us-east-1", "some_access_key", "some_secret_key")

        http = Http.new(SIGNER, client.endpoint)
        http.put("/document", "abcd")
      end

      it "passes additional headers, when provided" do
        WebMock.stub(:put, "https://s3.amazonaws.com/document")
          .with(body: "abcd", headers: {"Content-Length" => "4", "x-amz-meta-name" => "document"})
          .to_return(status: 200)

        client = Client.new("us-east-1", "some_access_key", "some_secret_key")

        http = Http.new(SIGNER, client.endpoint)
        http.put("/document", "abcd", {"x-amz-meta-name" => "document"})
      end

      it "accepts explicit Content-Length header for streaming IO without #size" do
        WebMock.stub(:put, "https://s3.amazonaws.com/stream")
          .with(headers: {"Content-Length" => "100"})
          .to_return(status: 200)

        client = Client.new("us-east-1", "some_access_key", "some_secret_key")
        http = Http.new(SIGNER, client.endpoint)

        r, w = IO.pipe
        w.write(Bytes.new(100, 65_u8))
        w.close

        resp = http.put("/stream", r, {"Content-Length" => "100"})
        resp.status_code.should eq(200)
      end

      it "sets X-Amz-Content-Sha256 to UNSIGNED-PAYLOAD for non-seekable streams" do
        WebMock.stub(:put, "https://s3.amazonaws.com/stream-unsigned")
          .with(headers: {"X-Amz-Content-Sha256" => "UNSIGNED-PAYLOAD", "Content-Length" => "5"})
          .to_return(status: 200)

        client = Client.new("us-east-1", "some_access_key", "some_secret_key")
        http = Http.new(SIGNER, client.endpoint)

        r, w = IO.pipe
        w.write("hello".to_slice)
        w.close

        resp = http.put("/stream-unsigned", r, {"Content-Length" => "5"})
        resp.status_code.should eq(200)
      end
    end

    describe "retries" do
      it "does not retry when retries is 0" do
        calls = 0
        WebMock.stub(:get, "https://s3.amazonaws.com/fail")
          .to_return do
            calls += 1
            raise IO::Error.new("connection reset")
          end

        client = Client.new("us-east-1", "key", "secret")
        http = Http.new(SIGNER, client.endpoint)

        expect_raises(IO::Error, "connection reset") do
          http.get("/fail", retries: 0)
        end
        calls.should eq(1)
      end

      it "rewinds rewindable body between retries" do
        calls = 0
        body = IO::Memory.new("test body")

        WebMock.stub(:put, "https://s3.amazonaws.com/retry")
          .to_return do
            calls += 1
            if calls == 1
              raise IO::Error.new("connection reset")
            else
              HTTP::Client::Response.new(200)
            end
          end

        client = Client.new("us-east-1", "key", "secret")
        http = Http.new(SIGNER, client.endpoint)

        resp = http.put("/retry", body, retries: 2)
        resp.status_code.should eq(200)
        calls.should eq(2)
      end

      it "raises clear error when retrying non-rewindable body" do
        calls = 0
        r, w = IO.pipe
        w.write(Bytes.new(10, 65_u8))
        w.close

        WebMock.stub(:put, "https://s3.amazonaws.com/stream-retry")
          .to_return do
            calls += 1
            raise IO::Error.new("connection reset")
          end

        client = Client.new("us-east-1", "key", "secret")
        http = Http.new(SIGNER, client.endpoint)

        expect_raises(S3::Exception, /Cannot retry request: body IO cannot be rewound/) do
          http.put("/stream-retry", r, {"Content-Length" => "10"}, retries: 2)
        end
        calls.should eq(1)
      end
    end

    describe "post" do
      it "passes additional headers, when provided" do
        WebMock.stub(:post, "https://s3.amazonaws.com/?")
          .with(headers: {"x-amz-meta-name" => "document"})

        client = Client.new("us-east-1", "some_access_key", "some_secret_key")

        Http.new(SIGNER, client.endpoint).post("/", headers: {"x-amz-meta-name" => "document"})
      end

      it "handles aws specific errors" do
        WebMock.stub(:post, "https://s3.amazonaws.com/?")
          .to_return(status: 404, body: ERROR_BODY)

        client = Client.new("us-east-1", "some_access_key", "some_secret_key")

        http = Http.new(SIGNER, client.endpoint)

        expect_raises S3::NoSuchKey, "The resource you requested does not exist" do
          http.post("/")
        end
      end

      it "handles bad responses" do
        WebMock.stub(:post, "https://s3.amazonaws.com/?")
          .to_return(status: 404)

        client = Client.new("us-east-1", "some_access_key", "some_secret_key")

        http = Http.new(SIGNER, client.endpoint)

        expect_raises S3::Exception do
          http.post("/")
        end
      end
    end

    describe "delete" do
      it "passes additional headers, when provided" do
        WebMock.stub(:delete, "https://s3.amazonaws.com/?")
          .with(headers: {"x-amz-mfa" => "123456"})

        client = Client.new("us-east-1", "some_access_key", "some_secret_key")

        Http.new(SIGNER, client.endpoint).delete("/", headers: {"x-amz-mfa" => "123456"})
      end

      it "handles aws specific errors" do
        WebMock.stub(:delete, "https://s3.amazonaws.com/?")
          .to_return(status: 404, body: ERROR_BODY)

        client = Client.new("us-east-1", "some_access_key", "some_secret_key")

        http = Http.new(SIGNER, client.endpoint)

        expect_raises S3::NoSuchKey, "The resource you requested does not exist" do
          http.delete("/")
        end
      end

      it "handles bad responses" do
        WebMock.stub(:delete, "https://s3.amazonaws.com/?")
          .to_return(status: 404)

        client = Client.new("us-east-1", "some_access_key", "some_secret_key")

        http = Http.new(SIGNER, client.endpoint)

        expect_raises S3::Exception do
          http.delete("/")
        end
      end
    end
  end
end
