#! /usr/bin/env ruby
#
#           DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#                   Version 2, December 2004
#
#           DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#  TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION
#
# 0. You just DO WHAT THE FUCK YOU WANT TO.
####################################################################

require 'optparse'
require 'mechanize'
require 'ripl'

options = {}

OptionParser.new do |o|
	options[:urls]      = []
	options[:regexes]   = []
	options[:recursive] = []

	o.on '-u', '--url URL...', Array, 'URLs to fetch from' do |urls|
		options[:urls].push *urls
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
end.parse!

if options[:urls].empty?
	options[:urls].push ARGV.shift
end

if options[:regexes].empty? && ARGV.empty?
	options[:regexes].push /(?i)\.(jpg|png|gif|jpeg)$/
else
	options[:regexes].push(*ARGV.map { |regex| Regexp.new(regex) })
end

puts "Matching with #{options[:regexes].join('; ')}"

$agent = Mechanize.new

def fetch (page, options)
	page.links.select { |l| l.href }.uniq(&:href).each {|link|
		if link.href.start_with? '//'
			link.href[0, 2] = "#{page.uri.scheme}://"
		end

		if options[:recursive].any? { |re| link.href.match(re) }
			fetch(link.click, options)
		end

		next unless options[:regexes].any? { |re| link.href.match(re) }

		unless file = $agent.head(link.href).filename rescue nil
			file = File.basename(link.href.sub(/\?.*$/, ''))
		end

		if File.exist?(file)
			puts "File #{file} already exists"

			next
		end

		puts "Downloading #{link.href} as #{file}"

		File.open(file, 'w') {|f|
			link.click.content.tap {|c|
				f.write(c.respond_to?(:read) ? c.read : c.to_str)
			}
		}
	}
end

options[:urls].each {|url|
	fetch($agent.get(url), options)
}
