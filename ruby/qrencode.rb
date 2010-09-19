#! /usr/bin/env ruby
# encoding: utf-8

require 'optimus'
require 'rqrcode'
require 'png'

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
  size = (3 * 2) + (code.module_count)

  canvas = PNG::Canvas.new(size, size, PNG::Color::White)

  code.modules.reverse.each_with_index {|row, y|
    row.each_with_index {|col, x|
      canvas[x + 3, y + 3] = PNG::Color::Black if col
    }
  }

  PNG.new(canvas).save(opt.params[:output])
end
