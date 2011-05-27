#! /usr/bin/env ruby
require 'open-uri'

options = {
  :replace => false,
  :regexps => [],
  :files   => []
}

skip = false
ARGV.each_with_index {|option, index|
  if skip
    skip = false
    next
  end

  case option
    when '-i'
      options[:replace] = true

    when '-e'
      options[:regexps].push(ARGV[index + 1])
      skip = true

    when /^-/
      fail "#{option}: Unknown option"

    else
      options[:files].push(option)
  end
}

options[:files].map! {|file|
  [file, open(file) {|f|
    f.read
  }]
}

if IO.select([STDIN], nil, nil, 0)
  options[:files].push [STDIN, STDIN.read]
elsif options[:files].empty?
  fail "What should I work on?"
end

options[:files].each {|(path, data)|
  options[:regexps].each {|regex|
    case regex
      when /^s(.)(.*?)\1(.*?)\1([gi]?)$/
        ($4.include?('g') ? data.method(:gsub!) : data.method(:sub!)).call(Regexp.new($2, $4), $3)

      when /^d(.)(.*?)\1([gi]?)$/
        ($4.include?('g') ? data.method(:gsub!) : data.method(:sub!)).call(Regexp.new($2, $4), '')
    end
  }
}

if options[:replace]
  options[:files].each {|(path, data)|
    next if path == STDIN

    open(path, 'w') {|f|
      f.write(data)
    }
  }
else
  options[:files].each {|(path, data)|
    print data
  }

  STDOUT.flush
end
