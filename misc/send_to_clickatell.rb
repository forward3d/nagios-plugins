#!/usr/bin/env ruby

require 'net/https'
require 'optparse'
require 'ostruct'
require 'uri'
require 'syslog/logger'

options = OpenStruct.new
$log = Syslog::Logger.new 'send_to_clickatell'

OptionParser.new do |opts|
  opts.on("-a", "--api_key API_KEY", "API key for Clickatell") do |a|
    options.api_key = a
  end
  opts.on("-u", "--user USER", "Username for Clickatell") do |u|
    options.user = u
  end
  opts.on("-p", "--pass PASS", "Password for Clickatell") do |p|
    options.pass = p
  end
  opts.on("-m", "--mobile MOBILE", "Mobile number to send message to") do |m|
    options.mobile = m
  end
  opts.on("-M", "--message MESSAGE", "Message to send") do |m|
    options.message = m
  end
end.parse!

# Validate options
missing_options = %w{
  api_key user pass mobile message
}.select {|option| options[option.to_sym].nil?}

unless missing_options.empty?
  puts "UNKNOWN: Missing options: #{missing_options.join(', ')}"
  exit 3
end

# Log message sent and to who
$log.info "To: #{options.mobile}; message: #{options.message}"

query = "api_id=#{URI.escape options.api_key}" +
        "&user=#{URI.escape options.user}" +
        "&password=#{URI.escape options.pass}" +
        "&to=#{URI.escape options.mobile}" +
        "&text=#{URI.escape options.message}" +
        "&concat=3"

uri = URI::HTTPS.build({
  :host  => "api.clickatell.com",
  :port  => 443,
  :path  => "/http/sendmsg",
  :query => query
})

begin
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  http.verify_mode = OpenSSL::SSL::VERIFY_NONE
  request = Net::HTTP::Get.new(uri.request_uri)
  response = http.request(request)
  raise "Non-200 status code returned" if response.code != "200"
  raise response.body unless response.body =~ /^ID/
rescue => e
  $log.error "Failed to send to #{options.mobile}: error was #{e.message}"
end

$log.info "Sent message to #{options.mobile} successfully"
