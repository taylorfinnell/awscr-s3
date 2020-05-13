require "../../spec_helper"

module Awscr
  module S3
    module Presigned
      describe Post do
        Spec.before_each do
          Timecop.freeze(Time.unix(1))
        end

        Spec.after_each do
          Timecop.return
        end

        describe "valid?" do
          it "returns true if bucket and policy are valid" do
            post = Post.new(
              region: "us-east-1",
              aws_access_key: "test",
              aws_secret_key: "test"
            )
            post.build { |b| b.condition("bucket", "t"); b.expiration(Time.local) }

            post.valid?.should be_true
          end

          it "returns false if bucket is missing" do
            post = Post.new(
              region: "us-east-1",
              aws_access_key: "test",
              aws_secret_key: "test"
            )
            post.build { |b| b.expiration(Time.local) }

            post.valid?.should be_false
          end

          it "returns false if policy is not valid" do
            post = Post.new(
              region: "us-east-1",
              aws_access_key: "test",
              aws_secret_key: "test"
            )
            post.build { |b| b.condition("bucket", "t") }

            post.valid?.should be_false
          end
        end

        describe "fields" do
          it "generates the same fields each time" do
            time = Time.unix(1)
            post = Post.new(
              region: "us-east-1",
              aws_access_key: "test",
              aws_secret_key: "test",
            )
            post.build { |b| b.condition("bucket", "t"); b.expiration(time) }

            post.fields.to_a.should eq(post.fields.to_a)
          end

          it "contains the policy field" do
            time = Time.unix(1)
            post = Post.new(
              region: "us-east-1",
              aws_access_key: "test",
              aws_secret_key: "test",
            )
            post.build { |b| b.condition("bucket", "t"); b.expiration(time) }

            field = post.fields.select { |f| f.key == "policy" }
            (field.size > 0).should be_true
            field.first.value.should eq("eyJleHBpcmF0aW9uIjoiMTk3MC0wMS0wMVQwMDowMDowMS4wMDBaIiwiY29uZGl0aW9ucyI6W3siYnVja2V0IjoidCJ9LHsieC1hbXotY3JlZGVudGlhbCI6InRlc3QvMTk3MDAxMDEvdXMtZWFzdC0xL3MzL2F3czRfcmVxdWVzdCJ9LHsieC1hbXotYWxnb3JpdGhtIjoiQVdTNC1ITUFDLVNIQTI1NiJ9LHsieC1hbXotZGF0ZSI6IjE5NzAwMTAxVDAwMDAwMVoifV19")
          end

          it "contains the signature field" do
            time = Time.unix(1)
            post = Post.new(
              region: "us-east-1",
              aws_access_key: "test",
              aws_secret_key: "test"
            )
            post.build { |b| b.condition("bucket", "t"); b.expiration(time) }

            field = post.fields.select { |f| f.key == "x-amz-signature" }
            (field.size > 0).should be_true
            field.first.value.should eq("c979e44c58c8df84951d121f7c66b62f2fbb3a2729dded7fd2708bdd763ff72e")
          end

          it "contains the credential field" do
            time = Time.unix(1)
            post = Post.new(
              region: "us-east-1",
              aws_access_key: "test",
              aws_secret_key: "test"
            )
            post.build { |b| b.condition("bucket", "t"); b.expiration(time) }

            field = post.fields.select { |f| f.key == "x-amz-credential" }
            (field.size > 0).should be_true
            field.first.value.should eq("test/19700101/us-east-1/s3/aws4_request")
          end

          it "contains the algorithm field" do
            time = Time.unix(1)
            post = Post.new(
              region: "us-east-1",
              aws_access_key: "test",
              aws_secret_key: "test"
            )
            post.build { |b| b.condition("bucket", "t"); b.expiration(time) }

            field = post.fields.select { |f| f.key == "x-amz-algorithm" }
            (field.size > 0).should be_true
            field.first.value.should eq(Signer::ALGORITHM)
          end

          it "contains the date field" do
            time = Time.unix(1)
            post = Post.new(
              region: "us-east-1",
              aws_access_key: "test",
              aws_secret_key: "test"
            )
            post.build { |b| b.condition("bucket", "t"); b.expiration(time) }

            field = post.fields.select { |f| f.key == "x-amz-date" }
            (field.size > 0).should be_true
            field.first.value.should eq("19700101T000001Z")
          end

          it "is a field collection" do
            post = Post.new(
              region: "us-east-1",
              aws_access_key: "test",
              aws_secret_key: "test"
            )

            post.fields.should be_a(FieldCollection)
          end
        end

        describe "url" do
          it "raises if no bucket field" do
            post = Post.new(
              region: "us-east-1",
              aws_access_key: "test",
              aws_secret_key: "test"
            )
            post.build { |b| b.expiration(Time.local) }

            expect_raises(Exception) do
              post.url
            end
          end

          it "includes the bucket field" do
            post = Post.new(
              region: "us-east-1",
              aws_access_key: "test",
              aws_secret_key: "test"
            )
            post.build { |b| b.expiration(Time.local); b.condition("bucket", "test") }

            post.url.should eq("http://test.s3.amazonaws.com")
          end
        end

        describe "fields" do
          it "has fields" do
            post = Post.new(
              region: "us-east-1",
              aws_access_key: "test",
              aws_secret_key: "test"
            )
            post.build { |b| b.expiration(Time.local) }

            post.fields.should be_a(FieldCollection)
          end
        end

        describe "build" do
          it "yields signed v2 policy" do
            post = Post.new(
              region: "us-east-1",
              aws_access_key: "test",
              aws_secret_key: "test",
              signer: :v2
            )
            policy = nil
            post.build { |p| p.expiration(Time.utc); policy = p }

            policy.should be_a(Policy)
            policy.as(Policy).fields["Signature"].should eq("vI0Km7fxOL7B9BunXFKM2/GvS1A=")
          end

          it "yields the signed v4 policy" do
            post = Post.new(
              region: "us-east-1",
              aws_access_key: "test",
              aws_secret_key: "test"
            )
            policy = nil
            post.build { |p| p.expiration(Time.utc); policy = p }

            policy.should be_a(Policy)
            policy.as(Policy).fields["x-amz-signature"].should eq("7dc0bf8fe1dcc2344f8ceaf3148a8898fbac6f074ccbe4edfbfac545be693add")
          end
        end
      end
    end
  end
end
