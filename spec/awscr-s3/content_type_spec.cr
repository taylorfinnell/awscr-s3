require "../spec_helper"

# An `IO` that responds to `#path`, but has none.
private class NilPathIO < IO::Memory
  getter path : String?
end

module Awscr::S3
  describe ContentType do
    describe "when the io isn't a file" do
      it "returns the default Content-Type" do
        io = IO::Memory.new("document")
        ContentType.get(io).should be(ContentType::DEFAULT)
      end
    end

    describe "when the io is a file" do
      it "returns the correct Content-Type" do
        tempfile = File.tempfile("foo", ".txt")
        file = File.open(tempfile.path)
        ContentType.get(file)[0..9].should eq("text/plain")
        tempfile.delete
      end
    end

    describe "when the io is a file and the extension is unknown" do
      it "returns the default Content-Type" do
        tempfile = File.tempfile("foo", ".spicy")
        file = File.open(tempfile.path)
        ContentType.get(file).should be(ContentType::DEFAULT)
        tempfile.delete
      end
    end

    describe "when the io has nil as path" do
      it "returns the default Content-Type" do
        io = NilPathIO.new("document")
        ContentType.get(io).should be(ContentType::DEFAULT)
      end
    end

    describe "custom types" do
      it "works" do
        MIME.register(".bhutjolokia", "ouch!")

        tempfile = File.tempfile("foo", ".bhutjolokia")
        file = File.open(tempfile.path)
        ContentType.get(file).should eq("ouch!")
        tempfile.delete
      end
    end
  end
end
