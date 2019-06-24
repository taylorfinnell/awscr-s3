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
        ContentType::TYPES.keys.each do |ext|
          tempfile = File.tempfile("foo", ext)
          file = File.open(tempfile.path)
          ContentType.get(file).should be(ContentType::TYPES[ext])
          tempfile.delete
        end
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
  end
end
