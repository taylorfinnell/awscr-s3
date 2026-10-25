require "../src/awscr-s3"
require "digest/sha256"

Log.setup_from_env

BUCKET = ENV.fetch("AWS_BUCKET", "examplebucket")
KEY    = ENV.fetch("AWS_KEY", "AKIAIOSFODNN7EXAMPLE")
SECRET = ENV.fetch("AWS_SECRET", "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY")
REGION = ENV.fetch("AWS_REGION", "us-east-1")

client = Awscr::S3::Client.new(
  region: REGION,
  aws_access_key: KEY,
  aws_secret_key: SECRET,
  endpoint: "http://127.0.0.1:9000"
)

client.put_bucket(BUCKET)

uploader = Awscr::S3::FileUploader.new(client)

def compute_checksum(io : IO) : String
  digest = Digest::SHA256.new
  buffer = Bytes.new(64 * 1024)
  while (read = io.read(buffer)) > 0
    digest.update(buffer[0, read])
  end
  digest.hexfinal
end

# Create a large file in 1MB chunks to avoid high upfront memory allocation
FILE_PATH = "/tmp/large.bin"
File.open(FILE_PATH, "w") do |file|
  chunk = Bytes.new(1024 * 1024)
  100.times do
    Random::Secure.random_bytes(chunk)
    file.write(chunk)
  end
end

checksum_before = File.open(FILE_PATH) do |f|
  compute_checksum(f)
end
puts "Checksum before upload: #{checksum_before}"

GC.collect
mem_before = GC.stats.total_bytes

File.open(FILE_PATH) do |f|
  uploader.upload(BUCKET, "large.bin", f)
end

GC.collect
mem_after = GC.stats.total_bytes
puts "Memory used: #{(mem_after - mem_before) / 1024 / 1024} MB"

checksum_after = client.get_object(BUCKET, "large.bin") do |resp|
  compute_checksum(resp.body_io)
end
puts "Checksum after upload:  #{checksum_after}"

if checksum_before == checksum_after
  puts "Consistency check: PASSED (checksums match)"
else
  abort "Consistency check: FAILED (expected #{checksum_before}, got #{checksum_after})"
end
