# Demonstrates the memory impact of DefaultHttpClientFactory vs PersistentHttpClientFactory.
#
# DefaultHttpClientFactory creates a new HTTP::Client (and TLS connection) for
# every S3 operation. The abandoned clients are only freed by GC finalization,
# but the GC sees a small Crystal object (~64 bytes) and has no urgency to
# collect — meanwhile each client holds ~600 KB of OpenSSL internal buffers
# in the C heap.
#
# In production, this causes RSS to grow by hundreds of MB per hour.
#
# Usage:
#   crystal run examples/memory_comparison.cr -- <endpoint> <region> <key> <secret> <bucket>
#
# Example:
#   crystal run examples/memory_comparison.cr -- https://sfo3.digitaloceanspaces.com sfo3 DOKEY DOSECRET mybucket

require "../src/awscr-s3"

endpoint = ARGV[0]? || abort("Usage: #{PROGRAM_NAME} <endpoint> <region> <key> <secret> <bucket>")
region = ARGV[1]? || abort("missing region")
key = ARGV[2]? || abort("missing key")
secret = ARGV[3]? || abort("missing secret")
bucket = ARGV[4]? || abort("missing bucket")

def rss_mb : Int64
  {% if flag?(:linux) %}
    File.read("/proc/self/status").lines
      .find(&.starts_with?("VmRSS:"))
      .try(&.split[1].to_i64) || 0_i64
  {% else %}
    `ps -o rss= -p #{Process.pid}`.strip.to_i64
  {% end %}
end

def run_test(label : String, client : Awscr::S3::Client, bucket : String, iterations : Int32)
  puts "\n=== #{label} ==="
  GC.collect
  rss_before = rss_mb

  iterations.times do |i|
    # Each list_objects call creates an HTTPS request
    client.list_objects(bucket, max_keys: 1).each { |_| }
    if (i + 1) % 50 == 0
      GC.collect
      puts "  #{i + 1}/#{iterations}: RSS = #{rss_mb} KB (delta: +#{rss_mb - rss_before} KB)"
    end
  end

  GC.collect
  rss_after = rss_mb
  delta = rss_after - rss_before
  per_request = iterations > 0 ? delta * 1024 / iterations : 0
  puts "  Final: RSS #{rss_before} -> #{rss_after} KB (delta: +#{delta} KB, ~#{per_request} bytes/request)"
end

iterations = 200

# Test 1: DefaultHttpClientFactory (creates new HTTP::Client per request)
default_client = Awscr::S3::Client.new(region, key, secret, endpoint: endpoint)
run_test("DefaultHttpClientFactory (new connection per request)", default_client, bucket, iterations)

# Force GC to clean up before next test
GC.collect
sleep 2.seconds
GC.collect

# Test 2: PersistentHttpClientFactory (reuses connection)
persistent_factory = Awscr::S3::PersistentHttpClientFactory.new
persistent_client = Awscr::S3::Client.new(region, key, secret,
  endpoint: endpoint,
  client_factory: persistent_factory)
run_test("PersistentHttpClientFactory (reuses connection)", persistent_client, bucket, iterations)

puts "\nDone. The default factory should show significant RSS growth per request,"
puts "while the persistent factory should show near-zero growth."
