#! /usr/bin/env ruby
require 'net/http'

link = if matches = ARGV.first.match(%r{fakku.*/(manga|doujinshi)/(.+?)(/|$)})
	"http://www.fakku.net/#{matches[1]}/#{matches[2]}/read"
else
	"http://www.fakku.net/manga/#{ARGV.first}/read"
end

cdn = Net::HTTP.get(URI.parse(link))[%r{return '(http://cdn\.fakku\.net.*?)'}, 1]

1.upto(999) {|i|
	file = "%03d.jpg" % i

	puts "Downloading #{file}"

	File.open(file, ?w) {|f|
		response = Net::HTTP.get_response(URI.parse("#{cdn}#{file}"))

		if response.is_a?(Net::HTTPSuccess)
			f.write(response.body)
		else
			exit
		end
	}
}
