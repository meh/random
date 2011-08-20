#! /usr/bin/env ruby
#
#           DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#                   Version 2, December 2004
#
# Copyleft meh. [http://meh.doesntexist.org | meh@paranoici.org]
#
#           DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#  TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION
#
# 0. You just DO WHAT THE FUCK YOU WANT TO.
####################################################################

require 'uri'
require 'net/http'

url   = URI.parse(ARGV.shift)
match = Regexp.new(ARGV.shift || '\.(jpg|png|gif|jpeg)$')

puts "Matching with #{match.inspect}"

URI.extract(Net::HTTP.get(url)) {|url|
  next unless url.match(match)

  puts "Downloading #{url}"

  File.open(File.basename(url), 'w') {|f|
    f.write(Net::HTTP.get(URI.parse(url)))
  }
}
