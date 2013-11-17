#!/usr/bin/env ruby

require 'rubygems'
require 'redis'
require 'optparse'

options = {}
required_options = [:warn, :crit, :host]

parser = OptionParser.new do |opts|

  opts.on("-H", "--host redishost", "Hostname of the Redis server") do |h|
    options[:host] = h
  end

  opts.on("-p", "--port port", "Port that Redis is listening on") do |p|
    options[:port] = p
  end

  opts.on("-w", "--warn number", "Number of failed jobs that will trigger a warning") do |w|
    options[:warn] = w
  end

  opts.on("-c", "--crit number", "Number of failed jobs that will trigger a critical") do |c|
    options[:crit] = c
  end
end

parser.parse!

if !required_options.all? { |k| options.has_key?(k) }
  options_missing = required_options - options.keys
  puts "Missing options: #{options_missing.join(", ")}"
  exit 3
end

begin
  redis = Redis.new(:host => options[:host], :port => options[:port] || 6379)
  failed_jobs = redis.llen("resque:failed")

  # Form perfdata
  perfdata = "'failed'=#{failed_jobs};#{options[:warn]};#{options[:crit]};0;"

  if failed_jobs > options[:crit].to_i
    puts "CRITICAL: Failed jobs: #{failed_jobs}|#{perfdata}"
    exit 2
  end

  if failed_jobs > options[:warn].to_i
    puts "WARNING: Failed jobs: #{failed_jobs}|#{perfdata}"
    exit 1
  end

  puts "OK: No failed jobs|#{perfdata}"
  exit 0

rescue => e
  puts "Problem connecting to Redis: #{e.message}"
  exit 3
end
