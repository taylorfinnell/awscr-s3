require "../../spec_helper"

module Awscr
  module S3
    module Presigned
      class TestField < PostField
        def serialize
        end
      end

      describe FieldCollection do
        it "is enumerable" do
          field = TestField.new("k", "v")
          fields = FieldCollection.new
          fields.push(field)

          collected = [] of PostField
          fields.each do |f|
            collected << f
          end

          collected.should eq([field])
        end

        it "can have fields added to it" do
          field = TestField.new("k", "v")

          fields = FieldCollection.new
          fields.push(field)

          fields.to_a.should eq([field])
        end

        it "is empty by default" do
          fields = FieldCollection.new

          fields.to_a.should eq([] of PostField)
        end

        it "does not add dupes" do
          field = TestField.new("k", "v")

          fields = FieldCollection.new
          5.times { fields.push(field) }

          fields.to_a.should eq([field])
        end

        describe "to_hash" do
          it "converts to named tuple" do
            fields = FieldCollection.new
            fields.push(TestField.new("k", "v"))

            fields.to_hash.should eq({"k" => "v"})
          end
        end

        describe "[]" do
          it "returns nil if no key found" do
            fields = FieldCollection.new
            fields["k"].should eq nil
          end

          it "can return a key value" do
            fields = FieldCollection.new
            fields.push(TestField.new("k", "v"))

            fields["k"].should eq "v"
          end

          it "does not care about case" do
            fields = FieldCollection.new
            fields.push(TestField.new("k", "v"))
            fields["K"].should eq "v"

            fields = FieldCollection.new
            fields.push(TestField.new("K", "v"))
            fields["k"].should eq "v"
          end

          it "can look up hypenated keys via an underscore" do
            fields = FieldCollection.new
            fields.push(TestField.new("k-v", "v"))
            fields["k_v"].should eq "v"
          end
        end
      end
    end
  end
end
