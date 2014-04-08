#!/usr/bin/env ruby

require 'optparse'

options = {}
OptionParser.new do |opts|
  opts.on("-d", "--directory DIRECTORY", "Logstash log directory") do |p|
    options[:directory] = p
  end
  opts.on("-b", "--buffer BUFFER", "Buffer size for processing files") do |b|
    options[:buffer] = b.to_i
  end
end.parse!

options[:directory] ||= '/var/www/logstash-forwarder'
options[:buffer] ||= 1024

begin
  Dir[options[:directory], '*.log'].each do |file|
    line = nil
    File.open(file, 'r') do |f|
      f.seek(-1, IO::SEEK_END)
      line_buffer = ""
      content = []
      while f.pos > options[:buffer]
        f.seek(0-options[:buffer], IO::SEEK_CUR)
        content = f.read(options[:buffer]).split($/)
        line_buffer = content.shift + line_buffer
        break unless content.empty?
        f.pos -= options[:buffer]
      end
      if f.pos < options[:buffer]
        f.pos = 0
        content.concat(f.read(options[:buffer]).split($/))
      end
      line = content[-1] + line_buffer
    end
    fields = line.split(" ")
    if fields[2] == "Stopping"
      puts "CRITICAL: logstash has stopped receiving events"
      exit 2
    end
  end
  puts "OK: logstash is running ok"
  exit 0
rescue => e
  puts "UNKNOWN: an exception has occurred while checking logstash: #{e.message}"
  exit 3
end