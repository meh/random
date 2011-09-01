#! /usr/bin/env ruby

Colors = Hash.new { 0 }.merge(
  :Black      => 0x0,
  :Blue       => 0x1,
  :Green      => 0x2,
  :Cyan       => 0x3,
  :Red        => 0x4,
  :Magenta    => 0x5,
  :Brown      => 0x6,
  :LightGray  => 0x7,
  :Gray       => 0x8,
  :LightBlue  => 0x9,
  :LightGreen => 0xA,
  :LightCyan  => 0xB,
  :LightRed   => 0xC,
  :Pink       => 0xD,
  :Yellow     => 0xE,
  :White      => 0xF
)

ARGV.each {|color|
  whole, foreground, background, blinking = color.match(/^([^:!]+)?(?::([^:!]+))?(!)?$/).to_a

  if whole
    puts "#{color} is 0x#{(
      ((Colors[(background.capitalize.to_sym rescue nil)] * 16) +
        Colors[(foreground.capitalize.to_sym rescue nil)]) |
      (blinking ? 0x80 : 0)
    ).to_s(16)}"
  else
    puts "#{color} is an invalid color"
  end
}
