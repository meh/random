#! /usr/bin/env ruby
require 'open-uri'

options = {
  :replace => false,
  :regexps  => []
}

skip = false
ARGV.each_with_index {|option, index|
  skip = false and next if skip

  case option
    when '-i' then options[:replace] = true
    when '-e' then options[:regexps].push(ARGV[index + 1]) and skip = true
    when /^-/ then fail "#{option}: Unknown option"
    else           options[:uri] = option
  end
}

data = if IO.select([STDIN], nil, nil, 0)
  STDIN.read
elsif options[:uri]
  open(options[:uri]).read
else
  fail "What should I read?"
end

options[:regexps].each {|regex|
  case regex
    when /^s(.)(.*?)\1(.*?)\1([gi]?)$/
      ($4.include?('g') ? data.method(:gsub!) : data.method(:sub!)).call(Regexp.new($2, $4), $3)

    when /^d(.)(.*?)\1([gi]?)$/
      ($4.include?('g') ? data.method(:gsub!) : data.method(:sub!)).call(Regexp.new($2, $4), '')

  end
}

if options[:replace] && options[:uri]
  File.open(options[:uri], 'w') {|f|
    f.write(data)
  }
else
  print data
  STDOUT.flush
end
