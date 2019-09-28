require "../../spec_helper"

module Awscr
  module S3
    module Presigned
      describe Policy do
        describe "eq" do
          it "adds a field" do
            policy = Policy.new
            policy.expiration(Time.local)
            policy.condition("test", "test")

            policy.fields.size.should eq 1
          end

          it "returns self" do
            policy = Policy.new
            policy.expiration(Time.local)

            policy.condition("test", "test").should eq policy
          end
        end

        describe "valid?" do
          it "returns true if expiration is set" do
            policy = Policy.new
            policy.expiration(Time.local)

            policy.valid?.should be_true
          end

          it "returns false if expiration is not set" do
            policy = Policy.new

            policy.valid?.should be_false
          end
        end

        describe "to_s" do
          it "returns policy as base64 encoded json" do
            policy = Policy.new
            policy.expiration(Time.unix(1_483_859_302))
            policy.condition("test", "test")

            policy.to_s.should eq("eyJleHBpcmF0aW9uIjoiMjAxNy0wMS0wOFQwNzowODoyMi4wMDBaIiwiY29uZGl0aW9ucyI6W3sidGVzdCI6InRlc3QifV19")
          end
        end

        describe "to_hash" do
          it "returns empty hash if policy is not valid" do
            policy = Policy.new
            policy.to_hash.should eq({} of String => String)
          end

          it "can be a hash" do
            policy = Policy.new
            policy.expiration(Time.unix(1_483_859_302))
            policy.condition("test", "test")

            policy.to_hash.should eq({
              "expiration" => "2017-01-08T07:08:22.000Z",
              "conditions" => [
                {"test" => "test"},
              ],
            })
          end
        end
      end
    end
  end
end
