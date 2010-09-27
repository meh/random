#! /usr/bin/env ruby
require 'uri'
require 'net/http'

url   = URI.parse(ARGV.shift)
match = Regexp.new(ARGV.shift || '\.(jpg|png|gif|jpeg)$')

puts "Matching with #{match.inspect}"

URI.extract(Net::HTTP.get(url)) {|url|
    if url.match(match)
        puts "Downloading #{url}"

        file = File.new(File.basename(url), 'w')
        file.write(Net::HTTP.get(URI.parse(url)))
        file.close
    end
}
