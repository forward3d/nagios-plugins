#!/usr/bin/env ruby

require 'aws-sdk'
require 'optparse'
require 'ostruct'

options = OpenStruct.new

OptionParser.new do |opts|

  opts.on("-a", "--access_key_id ACCESS_KEY_ID", "AWS access key ID") do |a|
    options.access_key_id = a
  end

  opts.on("-s", "--secret_access_key SECRET_ACCESS_KEY", "AWS secret access key") do |s|
    options.secret_access_key = s
  end

  opts.on("-i", "--instance_id INSTANCE_ID", "The instance ID to look for in loadbalancers") do |i|
    options.instance_id = i
  end
  
  opts.on("-r", "--region REGION", "The AWS region to look in") do |r|
    options.region = r
  end

end.parse!

missing_options = %w{access_key_id secret_access_key instance_id region}.select do |param|
  options.send(param.to_sym) == nil
end

if missing_options.length > 0
  puts "Missing options, use --help for help: #{missing_options.join(", ")}"
  exit 1
end

AWS.config({
  :access_key_id => options.access_key_id,
  :secret_access_key => options.secret_access_key,
  :region => options.region
})

# Search every loadbalancer for the instance and see if it's healthy in there.

elb_health_list = []
elb = AWS::ELB.new
elb.load_balancers.each do |lb|
  # See if the instance is in this LB
  instance = lb.instances[options.instance_id]
  if instance.exists?
    # Record the health status for this ELB
    health = {
      :state            => instance.elb_health[:state],
      :description      => instance.elb_health[:description],
      :reason_code      => instance.elb_health[:reason_code],
      :lb_name          => lb.name
    }
    elb_health_list << health
  end
end

# If we don't find any ELB health statuses, this instance is not in any LBs, which
# is a bad state!
if elb_health_list.empty?
  puts "UNKNOWN - instance '#{options.instance_id}' was not found in any ELBs in '#{options.region}'"
  exit 3
end

failures = false
formatted_status = elb_health_list.map do |health|
  failures = true if health[:state] != "InService"
  "LB '#{health[:lb_name]}', status '#{health[:state]}'"
end

if failures
  puts "CRITICAL: #{formatted_status.join("; ")}"
  exit 2
else
  puts "OK: #{formatted_status.join("; ")}"
  exit 0
end
