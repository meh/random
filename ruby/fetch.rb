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

require 'optparse'
require 'open-uri'

options = {}

OptionParser.new do |o|
	options[:urls]      = []
	options[:regexes]   = []
	options[:recursive] = []

	o.on '-u', '--url URL...', Array, 'URLs to fetch from' do |urls|
		options[:urls].push *urls.map { |url| URI.parse(url) }
	end

	o.on '-e', '--regexes REGEX...', Array, 'regexps to choose to match' do |regexes|
		options[:regexes].push *regexes.map { |regex| Regexp.new(regex) }
	end

	o.on '-r', '--recursive [REGEX...]', Array, 'match into the following recursive stuff' do |recursive|
		if recursive.empty?
			options[:recursive].push /(?i)\.(^jpg|png|gif|jpeg)$/
		else
			options[:recursive].push *recursive.map { |regex| Regexp.new(regex) }
		end
	end
end

options[:urls].push(URI.parse(ARGV.shift))

if options[:regexes].empty? && ARGV.empty?
	options[:regexes].push /(?i)\.(jpg|png|gif|jpeg)$/
else
	options[:regexes].push(*ARGV.map { |regex| Regexp.new(regex) })
end

puts "Matching with #{options[:regexes].join('; ')}"

def fetch (url, options)
	URI.extract(open(url).read).uniq.each {|url|
		if options[:recursive].any? { |re| url.match(re) }
			fetch(url)
		end

		next unless options[:regexes].any? { |re| url.match(re) }

		file = File.basename(url.sub(/\?.*$/, ''))

		if File.exist?(file)
			puts "File #{file} already exists"
			next
		end

		puts "Downloading #{url}"

		File.open(file, 'w') {|f|
			f.write(open(URI.parse(url)).read)
		}
	}
end

options[:urls].each {|url|
	fetch(url, options)
}
