#!/usr/bin/env ruby

require 'aws-sdk'
require 'pp'
require 'optparse'
require 'ostruct'

options = OpenStruct.new

OptionParser.new do |opts|
  
  opts.on("-r", "--region REGION", "AWS region the instance is in") do |r|
    options.region = r
  end

  opts.on("-a", "--access_key_id KEY", "AWS access key") do |a|
    options.access_key_id = a
  end

  opts.on("-s", "--secret_access_key KEY", "AWS secret access key") do |s|
    options.secret_access_key = s
  end

  opts.on("-i", "--instance_id ID", "Instance ID") do |i|
    options.instance_id = i
  end

end.parse!

AWS.config({
  :access_key_id => options.access_key_id,
  :secret_access_key => options.secret_access_key,
  :region => options.region
})

ec2 = AWS::EC2.new
resp = ec2.client.describe_instance_status({
  :instance_ids => [options.instance_id]})

status_info = resp[:instance_status_set].first
nagios_output = []
ok = true

system_status     = resp[:instance_status_set].first[:system_status][:status]
instance_status   = resp[:instance_status_set].first[:instance_status][:status]

system_status = status_info[:system_status][:status]
if system_status != "ok"
  nagios_output << "system_status check says: #{status_info[:system_status][:details][:name]}"
  ok = false
end
if instance_status != "ok"
  nagios_output << "instance_status check says: #{status_info[:instance_status][:details][:name]}"
  ok = false
end

if ok
  puts "OK: instance_status and system_status both report 'ok'"
  exit 0
else
  puts "CRITICAL: #{nagios_output.join("; ")}"
  exit 2
end
