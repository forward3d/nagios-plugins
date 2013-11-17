#!/usr/bin/env ruby

require 'csv'
require 'net/http'
require 'uri'
require 'optparse'
require 'ostruct'

options = OpenStruct.new

OptionParser.new do |opts|
  
  opts.on("-H", "--host HOST", "HAProxy hostname") do |h|
    options.host = h
  end

  opts.on("-p", "--port PORT", "HAProxy stats port") do |p|
    options.port = p
  end

  opts.on("-n", "--name NAME", "HAProxy proxy name") do |n|
    options.name = n
  end

  opts.on("-c", "--critical VALUE", "Return critical if queue is longer than VALUE") do |c|
    options.critical = c
  end

  opts.on("-w", "--warning VALUE", "Return warning if queue is longer than VALUE") do |w|
    options.warning = w
  end

end.parse!

missing_options = %w{host port name critical warning}.select do |param|
  options.send(param.to_sym) == nil
end

if missing_options.length > 0
  puts "Missing options, use --help for help: #{missing_options.join(", ")}"
  exit 1
end

uri = URI.parse("http://#{options.host}:#{options.port}/;csv")
response = Net::HTTP.get_response(uri)

response.body.each_line do |line|

  # Backend line tells us how many connections were queued going to the backend,
  # and it's the third field in the CSV row
  if line =~ /^#{options.name},BACKEND/
    queued = line.split(",")[2]
    if queued > options.critical
      puts "CRITICAL: HAProxy queue is #{queued}, critical value is #{options.critical}"
      exit 2
    end
    if queued > options.warning
      puts "WARNING: HAProxy queue is #{queued}, warning value is #{options.warning}"
      exit 1
    end
    puts "OK: HAProxy queue is #{queued}, critical is #{options.critical}, warning is #{options.warning}"
    exit 0
  end
end
