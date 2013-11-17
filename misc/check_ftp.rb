#!/usr/bin/env ruby

require 'net/ftp'
require 'optparse'

options = {}
OptionParser.new do |opts|
  opts.on("-H", "--host HOST", "Host to connect to") do |h|
    options[:host] = h
  end
  opts.on("-p", "--port PORT", "Port to connect to") do |p|
    options[:port] = p
  end
  opts.on("-u", "--username USERNAME", "Username to login with") do |u|
    options[:username] = u
  end
  opts.on("-P", "--password PASSWORD", "Password to login with") do |p|
    options[:password] = p
  end
  opts.on("-v", "--verbose", "Prints backtraces on exception (truncated by Nagios)") do |v|
    options[:verbose] = v
  end
end.parse!

missing_opts = %w{host port username password}.select {|o| options[o.to_sym].nil?}
unless missing_opts.empty?
  puts "UNKNOWN: missing options #{missing_opts.join(', ')}"
  exit 3
end
options[:verbose] ||= false

begin
  ftp = Net::FTP.new
  ftp.connect(options[:host], options[:port])
  ftp.login(options[:username], options[:password])
  ftp.passive = true
  ftp.list
  File.open("/tmp/ftpfile", "w") do |file|
    file.puts "This is test data from the check_ftp.rb Nagios check" 
  end
  ftp.puttextfile("/tmp/ftpfile", "nagios_test")
  nagios_test = ftp.list.find {|f| f =~ /nagios_test/}
  if nagios_test
    ftp.delete("nagios_test")
    puts "OK: logged in, uploaded file, tested file exists, deleted file"
    exit 0
  else
    puts "CRITICAL: uploaded file, but could not find it in listings"
    exit 2
  end
rescue => e
  puts "CRITICAL: exception - #{e.message}"
  puts e.backtrace.join("\n") if options[:verbose]
  exit 2
end
