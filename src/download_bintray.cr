require "http/client"

if ARGV.size != 1
  puts "Expecting a single argument."
  puts "Example: https://dl.bintray.com/<user>/"
  exit(0)
end

url = ARGV[0]

download(url, __DIR__)

# Recursively downloads files from bintray.
def download(url, dest)
  response = HTTP::Client.get url
  if response.status_code == 200
    # find links
    links = response.body.scan(/href="([^"]+)"[^>]*>([^<]+)<\/a>/)
    links.each do |l|
      href = l[1]
      text = l[2]
      new_dest = File.join(dest, text)
      new_url = "#{url}#{text}"
      is_dir = text.ends_with?("/")
      if is_dir
        puts "Entering #{new_url}"
        # create dir and recurse
        Dir.mkdir_p(new_dest)
        download(new_url, new_dest)
      else
        # Download file
        puts "Downloading #{new_url}"
        File.open(new_dest, mode: "w") do |f|
          HTTP::Client.get(new_url) do |resp|
            IO.copy(resp.body_io, f)
          end
        end
      end
    end
  else
    puts "#{response.status_code}: failed to read #{url}"
  end
end
