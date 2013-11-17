#!/usr/bin/env ruby

require 'json'
require 'net/http'
require 'openssl'

# Check the status of Github via their Status JSON API

# This endpoint has the last message + status
api_endpoint = "https://status.github.com/api/last-message.json"

begin
  # Get JSON from endpoint
  uri = URI.parse(api_endpoint)
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  http.verify_mode = OpenSSL::SSL::VERIFY_NONE
  status_json = JSON.parse http.get(uri.request_uri).body

  # Keys are status, body, created_on
  case status_json["status"]
  when "good"
    puts "OK - GitHub status is 'good', message: #{status_json["body"]}, at: #{status_json["created_on"]}"
    exit 0
  when "minor"
    puts "WARNING - GitHub status is 'minor', message: #{status_json["body"]}, at: #{status_json["created_on"]}"
    exit 1
  when "major"
    puts "CRITICAL - GitHub status is 'major', message: #{status_json["body"]}, at: #{status_json["created_on"]}"
    exit 2
  end

rescue => e
  puts "UNKNOWN - exception trying to get GitHub status, message is: #{e.message}"
  exit 3
end
