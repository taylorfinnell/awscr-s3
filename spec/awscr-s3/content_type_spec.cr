require "../spec_helper"

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
        ContentType.get(file).should eq("text/plain")
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
        io = UNIXSocket.new(fd: 1)
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
