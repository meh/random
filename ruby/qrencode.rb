#! /usr/bin/env ruby
# encoding: utf-8
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


require 'optimus'
require 'rqrcode'
require 'chunky_png'

BORDER = 1

opt = Optimus.new {|o|
  o.set(
    :type => :numeric,

    :long    => 'level',
    :short   => 'l',
    :default => 4
  )

  o.set(
    :long    => 'error',
    :short   => 'e',
    :default => 'L'
  )

  o.set(
    :long  => 'output',
    :short => 'o'
  )

  o.set(
    :type => :numeric,

    :long    => 'pixel',
    :short   => 'p',
    :default => 3,
  )
}

begin
  code = RQRCode::QRCode.new(opt.arguments.first(), {
    :size  => opt.params[:level],
    :level => opt.params[:error].downcase.to_sym
  })
rescue RQRCode::QRCodeRunTimeError => e
  puts e.to_s.capitalize
  exit 1
end


if !opt.params[:output]
  puts "\n\n"

  code.to_s(:true => '██', :false => '  ').lines.each {|line|
    print "    #{line}"
  }

  puts "\n\n\n"
else
  size = (BORDER * 2) + (code.module_count)

  img = ChunkyPNG::Image.new(size, size, ChunkyPNG::Color::WHITE)

  code.modules.each_with_index {|row, y|
    row.each_with_index {|col, x|
      img[x + BORDER, y + BORDER] = ChunkyPNG::Color::BLACK if col
    }
  }

  img.save(opt.params[:output])
end
