require "spec"
require "timecop"
require "webmock"
require "./fixtures"

# 1.to 10000 { |i| puts "123456789012345678901234567890123456789012345678901234567890 #{i}"; STDOUT.flush }

STDERR.sync = true # IO::FileDescriptor.from_stdio(2)
STDOUT.sync = true # IO::FileDescriptor.from_stdio(1)

Spec.around_each do |example|
  WebMock.reset
  # Integration tests should allow to send requests
  integration = example.example.all_tags.includes?("integration") || \
     example.example.file.includes?("spec/integration")
  WebMock.allow_net_connect = integration

  begin
    STDERR.print "===> before run #{example.example.description} : #{example.example.file}\n"
    STDOUT.flush
    example.run
    STDOUT.flush
  rescue ex : IO::Error
    STDERR.print "E: handled ex: 'ex` #{ex.target}"
    ex.inspect_with_backtrace(STDERR)

    io = IO::FileDescriptor.from_stdio(1)
    io.puts "((((((((((((((((((((((((((((((((((((((("
    io.flush
  end
end

Spec.after_each do
  Timecop.return
end

require "../src/awscr-s3"
require "./support/**"
