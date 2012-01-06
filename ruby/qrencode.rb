#! /usr/bin/env ruby
# encoding: utf-8
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
require 'rqrcode'
require 'chunky_png'

options = {}

OptionParser.new do |o|
	options[:border] = 1
	options[:error]  = ?L
	options[:size]   = 3

	o.on '-l', '--level VALUE', Integer, 'the compression level' do |value|
		options[:level] = value
	end

	o.on '-e', '--error VALUE', 'the error level' do |value|
		options[:error] = value
	end

	o.on '-o', '--output PATH', 'the path to save a PNG' do |path|
		options[:output] = path
	end

	o.on '-p', '--pixel SIZE', Integer, 'the pixel size' do |size|
		options[:pixel] = size
	end

	o.on '-b', '--border BORDER', Integer, 'the border size' do |size|
		options[:border] = size
	end
end.parse!

begin
  code = RQRCode::QRCode.new(ARGV.first,
    size:  options[:level],
    level: options[:error].downcase.to_sym
  )
rescue RQRCode::QRCodeRunTimeError => e
  puts e.to_s.capitalize
  exit 1
end

if !options[:output]
  puts "\n\n"

  code.to_s(true: '██', false: '  ').lines.each {|line|
    print "    #{line}"
  }

  puts "\n\n\n"
else
  size = (options[:border] * 2) + (code.module_count)

  img = ChunkyPNG::Image.new(size, size, ChunkyPNG::Color::WHITE)

  code.modules.each_with_index {|row, y|
    row.each_with_index {|col, x|
      img[x + options[:border], y + options[:border]] = ChunkyPNG::Color::BLACK if col
    }
  }

  img.save(options[:output])
end
