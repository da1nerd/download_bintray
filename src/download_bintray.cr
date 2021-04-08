require "http/client"
require "option_parser"
require "file_utils"

BINTRAY_URL = "https://dl.bintray.com/"
destination_dir = __DIR__
replace_existing = false
user = ""
verbose = false
check_downloads = false
prune = false

OptionParser.parse do |parser|
  parser.banner = "Download Bintray. Use this to download all of your bintray artifacts."
  parser.on "-u USERNAME", "--user=USERNAME", "Your bintray username" do |username|
    user = username
  end
  parser.on "-r", "--replace", "Replace downloaded files instead of skipping them." do
    replace_existing = true
  end
  parser.on "-c", "--check", "Check that the artifacts were downloaded correctly." do
    check_downloads = true
  end
  parser.on "-v", "--verbose", "Display all the log messages." do
    verbose = true
  end
  parser.on "-d DIR", "--dir DIR", "The destination directory. Default is the current directory." do |dir|
    destination_dir = dir
  end
  parser.on "-p", "--prune", "Removes the temporary file caches. Make sure to check your downloads first with -c" do |dir|
    prune = true
  end
  parser.on "-h", "--help", "Show help" do
    puts parser
    exit
  end
end

if prune
  puts "Pruning the files. This will remove caches used to speed things up when running this multiple times."
  puts "Clearing the cache will make things take a long time if you need to finish downloading things."
  puts "Are you sure? y/N"
  should_continue = gets
  if should_continue == "y" || should_continue == "Y"
    clean_dir(destination_dir)
  else
    puts "Aborting."
  end
  exit
end

unless user.empty?
  download_url = "#{BINTRAY_URL}#{user}/"
  puts "Downloading artifacts from #{download_url}"
  if check_downloads
    puts "Files will be verified after download. This will take longer."
  end
  download(download_url, destination_dir, replace_existing, verbose, check_downloads)
else
  puts "You must give a username. Use --help for details."
end

def clean_dir(dir)
  puts "Pruning #{dir}"
  Dir.each_child(dir) do |child|
    file_path = File.join(dir, child)
    checked_file = make_check_file(file_path)

    if File.directory?(file_path)
      clean_dir(file_path)
    elsif child == "index.html"
      File.delete(file_path)
    elsif File.exists?(checked_file)
      File.delete(checked_file)
    end
  end
end

# Recursively downloads files from bintray.
def download(url, dest, replace_existing, verbose, check_downloads)
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
      download(new_url, new_dest, replace_existing, verbose, check_downloads)
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
      if check_downloads
        log("Checking #{new_dest}", verbose)
        if !check_file(new_url, new_dest)
          log("Replacing #{new_dest} because file check failed", verbose)
          download_file(new_url, new_dest)
          if !check_file(new_url, new_dest)
            log("Failed to correct #{new_dest}", verbose)
          end
        end
      end
    end
  end
end

# Downloads a binary file
def download_file(url, dest)
  # clear the check cache
  checked_file = make_check_file(dest)
  File.delete(checked_file) if File.exists?(checked_file)
  # perform the download
  File.open(dest, mode: "w") do |f|
    HTTP::Client.get(url) do |resp|
      IO.copy(resp.body_io, f)
    end
  end
end

# Makes the path of the check validation file.
# This file acts as a cache so we don't have to check more than once.
# *file_path* is the file being checked
def make_check_file(file_path)
  File.join(File.dirname(file_path), ".checked.#{File.basename(file_path)}")
end

# Verify the downloaded files has the correct file size
def check_file(url, dest)
  checked_file = make_check_file(dest)
  if File.exists?(checked_file)
    return true
  end

  local_size = File.size(dest)
  response = HTTP::Client.head(url)
  remote_size = response.headers["Content-Length"].to_i32
  is_valid = local_size == remote_size
  if is_valid
    # cache it so reruns are faster
    FileUtils.touch(checked_file)
  end
  return is_valid
end

# Logs a progress message to the terminal.
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
    elsif message.starts_with?("Checking")
      return
    else
      printf(".")
    end
  end
end
