require "http/client"
require "option_parser"

BINTRAY_URL = "https://dl.bintray.com/"
destination_dir = __DIR__
replace_existing = false
user = ""
verbose = false

OptionParser.parse do |parser|
  parser.banner = "Download Bintray. Use this to download all of your bintray artifacts."
  parser.on "-u USERNAME", "--user=USERNAME", "Your bintray username" do |username|
    user = username
  end
  parser.on "-r", "--replace", "Replace downloaded files instead of skipping them." do
    replace_existing = true
  end
  parser.on "-v", "--verbose", "Display all the log messages." do
    verbose = true
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
  download_url = "#{BINTRAY_URL}#{user}/"
  puts "Downloading artifacts from #{download_url}"
  download(download_url, destination_dir, replace_existing, verbose)
else
  puts "You must give a username. Use --help for details."
end

# Recursively downloads files from bintray.
def download(url, dest, replace_existing, verbose)
  # Read html
  index_file = File.join(dest, "index.html")
  if replace_existing || !File.exists?(index_file)
    response = HTTP::Client.get url
    if response.status_code == 200
      body = response.body
      File.write(index_file, body)
    else
      log("Failed to read #{url}", verbose)
      return
    end
  else
    # load from cache
    body = File.read(index_file)
  end

  # find links
  links = body.scan(/href="([^"]+)"[^>]*>([^<]+)<\/a>/)
  links.each do |l|
    href = l[1]
    text = l[2]
    new_dest = File.join(dest, text)
    new_url = "#{url}#{text}"
    is_dir = text.ends_with?("/")
    if is_dir
      log("Entering #{new_url}", verbose)
      # create dir and recurse
      Dir.mkdir_p(new_dest)
      download(new_url, new_dest, replace_existing, verbose)
    else
      # Download file
      if replace_existing && File.exists?(new_dest)
        log("Replacing #{new_dest}", verbose)
        download_file(new_url, new_dest)
      elsif !File.exists?(new_dest)
        log("Downloading #{new_dest}", verbose)
        download_file(new_url, new_dest)
      else
        log("Skipping #{new_dest}", verbose)
      end
    end
  end
end

def download_file(url, dest)
  File.open(dest, mode: "w") do |f|
    HTTP::Client.get(url) do |resp|
      IO.copy(resp.body_io, f)
    end
  end
end

def log(message, verbose)
  if verbose
    puts message
  else
    if message.starts_with?("Replacing")
      printf("r")
    elsif message.starts_with?("Downloading")
      printf("d")
    elsif message.starts_with?("Skipping")
      printf("s")
    elsif message.starts_with?("Failed")
      printf("e")
    else
      printf(".")
    end
  end
end
