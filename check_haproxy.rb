#!/usr/bin/env ruby

require 'net/http'
require 'optparse'

# Constants
CRITICAL = 2
WARNING = 1
OK = 0

options = {}
OptionParser.new do |opts|
  opts.on("-h", "--host HOST", "Hostname of the HAProxy server") do |h|
    options[:host] = h
  end
  opts.on("-p", "--port PORT", "Port the stats interface is listening on") do |p|
    options[:port] = p
  end
  opts.on("-t", "--test TESTSPEC", 
          "Test specification:",
          "Specify four values separated by commas",
          "First value is the name of the farm in HAProxy's configuration",
          "Second value is either 'u', or 'd'", 
          " - specify 'u' to have thresholds applied to number of UP servers",
          " - specify 'd' to have thresholds applied to number of DOWN servers",
          "Second value is number of backends UP or DOWN that will trigger a WARNING",
          "Third value is number of backends UP or DOWN that will trigger a CRITICAL",
          "Examples:",
          "  web,u,3,1 would trigger WARNING if <=3 backends were UP, CRITICAL if <=1 was UP",
          "  web,d,1,10 would trigger WARNING if >=1 backends were DOWN, CRITICAL if >=10 DOWN"
         ) do |t|
    options[:test] ||= []
    options[:test] << t
  end
end.parse!

if options[:host].nil?
  puts "-h option is missing"
  exit 3
end

if options[:port].nil?
  puts "-p option is missing"
  exit 3
end

uri = URI.parse "http://#{options[:host]}:#{options[:port]}/;csv"
response = Net::HTTP.get_response(uri)

def is_up?(entry)
  entry.split(",")[17] == "UP"
end

def is_down?(entry)
  entry.split(",")[17] == "DOWN"
end

def parse_test_specs(test_specs)
  test_spec_info = {}
  test_specs.each do |test_spec|
    # Validate spec
    if test_spec.split(",").size != 4
      puts "testspec '#{test_spec}' is not valid; does not have 4 fields"
      exit 3
    end
    (farm, updown, warning, critical) = test_spec.split(",")

    # Validate updown option
    case updown
    when 'u'
      updown = :up
    when 'd'
      updown = :down
    else
      puts "testspec '#{test_spec}' has an invalid value for the second field - must be 'u' or 'd'"
      exit 3
    end

    # Validate warning/critical values
    unless warning =~ /^\d+$/
      puts "testspec '#{test_spec}' has an invalid value for the third field - must be an integer"
      exit 3
    end
    unless critical =~ /^\d+$/
      puts "testspec '#{test_spec}' has an invalid value for the fourth field - must be an integer"
      exit 3
    end

    # Validate warning/critical make sense given the updown option
    if updown == :up and warning.to_i < critical.to_i
      puts "testspec '#{test_spec}' has warning less than critical for an 'up' type check"
      exit 3
    end
    if updown == :down and warning.to_i > critical.to_i
      puts "testspec '#{test_spec}' has warning more than critical for a 'down' type check"
      exit 3
    end
    test_spec_info[farm] = {:updown => updown, :warning => warning.to_i, :critical => critical.to_i}
  end 
  test_spec_info
end

def set_status(value)
  $status = value if $status < value
end

# Output info
$status = 0
output = []

# Collect each service's lines from the CSV
services = {}
response.body.each_line do |line|
  # Skip comments
  next if line =~ /^#/
  service_name = line.split(",")[0]
  services[service_name] = [] if services[service_name].nil?
  # Snip out the FRONTEND/BACKEND lines, since they aren't 'real servers'
  next if line.split(",")[1] =~ /^BACKEND|FRONTEND$/
  services[service_name] << line
end

test_specs = parse_test_specs(options[:test]) unless options[:test].nil?
test_specs ||= {}

services.each_pair do |service,entries|
  down_hosts = entries.reject {|entry| is_up?(entry)}.size
  up_hosts   = entries.reject {|entry| is_down?(entry)}.size
  if test_specs.has_key?(service)
    test_spec = test_specs[service]

    if test_spec[:updown] == :up
      if up_hosts <= test_spec[:warning] and up_hosts > test_spec[:critical]
        output << "Service #{service} has only #{up_hosts} up"
        set_status(WARNING)
      end
      if up_hosts <= test_spec[:critical]
        output << "Service #{service} has only #{up_hosts} up"
        set_status(CRITICAL)
      end
    end

    if test_spec[:updown] == :down
      if down_hosts >= test_spec[:warning] and down_hosts < test_spec[:critical]
        output << "Service #{service} has #{down_hosts} down"
        set_status(WARNING)
      end
      if down_hosts >= test_spec[:critical]
        output << "Service #{service} has #{down_hosts} down"
        set_status(CRITICAL)
      end
    end

  else
    if down_hosts > 0
      output << "Service #{service} has #{down_hosts} down"
      set_status(CRITICAL)
    end
  end
end

if output.empty?
  puts "All services within limits"
else
  puts output.join(", ")
end

exit $status
