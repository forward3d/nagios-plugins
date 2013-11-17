#!/usr/bin/env ruby

require 'redis'
require 'optparse'
require 'json'
require 'time'

options = {}

OptionParser.new do |opts|
  opts.banner = "Usage: check_long_running_resque_jobs.rb [options]"
  opts.on("-H", "--host HOSTNAME", "Host that Redis is running on") do |h|
    options[:host] = h
  end
  opts.on("-p", "--port PORT", "Port that Redis is running on") do |p|
    options[:port] = p
  end
  opts.on("-t", "--time TIME", "Number of seconds job has been running for to alert") do |t|
    options[:time] = t.to_i
  end
end.parse!

if options[:host].nil?
  puts "UNKNOWN: Missing -h option"
  exit 3
end

# Defaults
options[:port] ||= 6379
options[:time] ||= 3600

begin
  redis = Redis.new(:host => options[:host], :port => options[:port])
  worker_keys = redis.smembers("resque:workers").map {|w| "resque:worker:#{w}"}
  long_running_workers = []
  worker_keys.each do |w|
    worker_data = redis.get(w)
    next if worker_data.nil?
    critical_time = Time.now - options[:time]
    if Time.parse(JSON.parse(worker_data)["run_at"]) < critical_time
      long_running_workers << w
    end
  end
  if long_running_workers.size > 0
    puts "CRITICAL: #{long_running_workers.size} long running jobs"
    exit 2
  else
    puts "OK: no long running jobs"
    exit 0
  end
rescue => e
  puts "UNKNOWN: exception occurred while connecting to Redis: #{e.message}"
  exit 3
end
