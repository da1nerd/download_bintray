require "http/client"
require "option_parser"

BINTRAY_URL = "https://dl.bintray.com/"
destination_dir = __DIR__
replace_existing = false
user = ""

OptionParser.parse do |parser|
  parser.banner = "Download Bintray. Use this to download all of your bintray artifacts."
  parser.on "-u USERNAME", "--user=USERNAME", "Your bintray username" do |username|
    user = username
  end
  parser.on "-r", "--replace", "Replace downloaded files instead of skipping them." do
    replace_existing = true
  end
  parser.on "-d DIR", "--dir DIR", "The destination directory. Default is the current directory." do |dir|
    destination_dir = dir
  end
  parser.on "-h", "--help", "Show help" do
    puts parser
    exit
  end
end

unless user.empty?
  download("#{BINTRAY_URL}#{user}/", destination_dir, replace_existing)
else
  puts "You must give a username. Use --help for details."
end

# Recursively downloads files from bintray.
def download(url, dest, replace_existing)
  response = HTTP::Client.get url
  if response.status_code == 200
    # find links
    links = response.body.scan(/href="([^"]+)"[^>]*>([^<]+)<\/a>/)
    links.each do |l|
      href = l[1]
      text = l[2]
      new_dest = File.join(dest, text)
      puts new_dest
      new_url = "#{url}#{text}"
      is_dir = text.ends_with?("/")
      if is_dir
        puts "Entering #{new_url}"
        # create dir and recurse
        Dir.mkdir_p(new_dest)
        download(new_url, new_dest, replace_existing)
      else
        # Download file
        puts "Downloading #{new_url}"
        if replace_existing || !File.exists?(new_dest)
          File.open(new_dest, mode: "w") do |f|
            HTTP::Client.get(new_url) do |resp|
              IO.copy(resp.body_io, f)
            end
          end
        end
      end
    end
  else
    puts "#{response.status_code}: failed to read #{url}"
  end
end
