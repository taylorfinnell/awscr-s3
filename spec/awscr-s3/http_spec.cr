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

        http = Http.new(SIGNER)

        http.get("/").status_code.should eq 200
      end

      it "sets the correct endpoint with a defined region" do
        WebMock.stub(:get, "https://s3-eu-west-1.amazonaws.com/")
          .to_return(status: 200)

        http = Http.new(SIGNER, "eu-west-1")

        http.get("/").status_code.should eq 200
      end

      it "can set a custom endpoint" do
        WebMock.stub(:get, "https://nyc3.digitaloceanspaces.com")
          .to_return(status: 200)

        http = Http.new(SIGNER, custom_endpoint: "https://nyc3.digitaloceanspaces.com")

        http.get("/").status_code.should eq 200
      end

      it "can set a custom endpoint with a port" do
        WebMock.stub(:get, "http://127.0.0.1:9000")
          .to_return(status: 200)

        http = Http.new(SIGNER, custom_endpoint: "http://127.0.0.1:9000")

        http.get("/").status_code.should eq 200
      end
    end

    describe "get" do
      it "handles aws specific errors" do
        WebMock.stub(:get, "https://s3.amazonaws.com/sup?")
          .to_return(status: 404, body: ERROR_BODY)

        http = Http.new(SIGNER)

        expect_raises S3::NoSuchKey, "The resource you requested does not exist" do
          http.get("/sup")
        end
      end

      it "handles bad responses" do
        WebMock.stub(:get, "https://s3.amazonaws.com/sup?")
          .to_return(status: 404)

        http = Http.new(SIGNER)

        expect_raises S3::Exception do
          http.get("/sup")
        end
      end

      context "with body_io" do
        it "handles aws specific errors" do
          WebMock.stub(:get, "https://s3.amazonaws.com/sup?")
            .to_return(status: 404, body: ERROR_BODY)

          http = Http.new(SIGNER)

          expect_raises S3::NoSuchKey, "The resource you requested does not exist" do
            http.get("/sup") do |response|
              pp response
            end
          end
        end

        it "handles bad responses" do
          WebMock.stub(:get, "https://s3.amazonaws.com/sup?")
            .to_return(status: 404)

          http = Http.new(SIGNER)

          expect_raises S3::Exception do
            http.get("/sup") do |response|
              pp response
            end
          end
        end
      end
    end

    describe "head" do
      it "handles aws specific errors" do
        WebMock.stub(:head, "https://s3.amazonaws.com/?")
          .to_return(status: 404, body: ERROR_BODY)

        http = Http.new(SIGNER)

        expect_raises S3::Exception, "The resource you requested does not exist" do
          http.head("/")
        end
      end

      it "handles bad responses" do
        WebMock.stub(:head, "https://s3.amazonaws.com/?")
          .to_return(status: 404)

        http = Http.new(SIGNER)

        expect_raises S3::Exception do
          http.head("/")
        end
      end
    end

    describe "put" do
      it "handles aws specific errors" do
        WebMock.stub(:put, "https://s3.amazonaws.com/?")
          .to_return(status: 404, body: ERROR_BODY)

        http = Http.new(SIGNER)

        expect_raises S3::NoSuchKey, "The resource you requested does not exist" do
          http.put("/", "")
        end
      end

      it "handles bad responses" do
        WebMock.stub(:put, "https://s3.amazonaws.com/?")
          .to_return(status: 404)

        http = Http.new(SIGNER)

        expect_raises S3::Exception do
          http.put("/", "")
        end
      end

      it "sets the Content-Length header by default" do
        WebMock.stub(:put, "https://s3.amazonaws.com/document")
          .with(body: "abcd", headers: {"Content-Length" => "4"})
          .to_return(status: 200)

        http = Http.new(SIGNER)
        http.put("/document", "abcd")
      end

      it "passes additional headers, when provided" do
        WebMock.stub(:put, "https://s3.amazonaws.com/document")
          .with(body: "abcd", headers: {"Content-Length" => "4", "x-amz-meta-name" => "document"})
          .to_return(status: 200)

        http = Http.new(SIGNER)
        http.put("/document", "abcd", {"x-amz-meta-name" => "document"})
      end
    end

    describe "post" do
      it "passes additional headers, when provided" do
        WebMock.stub(:post, "https://s3.amazonaws.com/?")
          .with(headers: {"x-amz-meta-name" => "document"})

        Http.new(SIGNER).post("/", headers: {"x-amz-meta-name" => "document"})
      end

      it "handles aws specific errors" do
        WebMock.stub(:post, "https://s3.amazonaws.com/?")
          .to_return(status: 404, body: ERROR_BODY)

        http = Http.new(SIGNER)

        expect_raises S3::NoSuchKey, "The resource you requested does not exist" do
          http.post("/")
        end
      end

      it "handles bad responses" do
        WebMock.stub(:post, "https://s3.amazonaws.com/?")
          .to_return(status: 404)

        http = Http.new(SIGNER)

        expect_raises S3::Exception do
          http.post("/")
        end
      end
    end

    describe "delete" do
      it "passes additional headers, when provided" do
        WebMock.stub(:delete, "https://s3.amazonaws.com/?")
          .with(headers: {"x-amz-mfa" => "123456"})

        Http.new(SIGNER).delete("/", headers: {"x-amz-mfa" => "123456"})
      end

      it "handles aws specific errors" do
        WebMock.stub(:delete, "https://s3.amazonaws.com/?")
          .to_return(status: 404, body: ERROR_BODY)

        http = Http.new(SIGNER)

        expect_raises S3::NoSuchKey, "The resource you requested does not exist" do
          http.delete("/")
        end
      end

      it "handles bad responses" do
        WebMock.stub(:delete, "https://s3.amazonaws.com/?")
          .to_return(status: 404)

        http = Http.new(SIGNER)

        expect_raises S3::Exception do
          http.delete("/")
        end
      end
    end
  end
end
