#! /usr/bin/env ruby
require 'net/http'
require 'uri'
require 'optimus'

HOST = 'http://view.thespectrum.net'

opt = Optimus.new {|o|
  o.set(
    :long  => 'output',
    :short => 'o'
  )
}

MANGA = opt.arguments.shift || exit

volumes = 1 .. Net::HTTP.get(URI.parse("#{HOST}/series/#{MANGA.downcase}-volume-01.html")).match(%r{(\d+)</option></select>})[1].to_i

puts "#{MANGA.capitalize} exists, downloading."

Dir.mkdir("#{opt.params[:o] || MANGA.capitalize}") rescue nil
Dir.chdir("#{opt.params[:o] || MANGA.capitalize}")

volumes.each {|volume|
  directory = "#{MANGA.capitalize} #{'%02d' % [volume]}"
  Dir.mkdir(directory) rescue nil
  Dir.chdir(directory)

  puts "Downloading #{directory}."

  pages = 1 .. Net::HTTP.get(URI.parse("#{HOST}/series/#{MANGA.downcase}-volume-#{'%02d' % [volume]}.html")).match(/of (\d+)/)[1].to_i

  pages.each {|page|
    file = "#{'%03d' % [page]}.jpg"

    if File.exists?(file) && File.size(file) > 0
      puts "Already have #{page}/#{pages.last} (volume #{volume}/#{volumes.last})."
      next
    else
      puts "Downloading page #{page}/#{pages.last} (volume #{volume}/#{volumes.last})."
    end

    begin
      path = Net::HTTP.get(URI.parse("#{HOST}/series/#{MANGA.downcase}-volume-#{'%02d' % [volume]}.html?ch=Volume+#{'%02d' % [volume]}&page=#{page}")).match(/<img src="(.*?\.jpg)"/)[1] rescue nil

      if !path
        puts "Couldn't download page #{page} (#{"#{HOST}/series/#{MANGA.downcase}-volume-#{'%02d' % [volume]}.html?ch=Volume+#{'%02d' % [volume]}&page=#{page}"}."
        next
      end

      file = File.new(file, 'w')
      file.write(Net::HTTP.get(URI.parse("#{HOST}#{URI.encode(path)}")))
      file.close
    rescue Errno::ETIMEDOUT
      retry
    end
  }

  Dir.chdir('..')
}

Dir.chdir('..')
