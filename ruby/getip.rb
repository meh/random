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

require 'net/http'
require 'uri'
require 'resolv'
require 'getoptlong'

args = GetoptLong.new(
    ['--version', '-v', GetoptLong::NO_ARGUMENT],
    ['--ip2location', '-i', GetoptLong::NO_ARGUMENT],
    ['--maxmind', '-m', GetoptLong::NO_ARGUMENT]
)

host = 'maxmind'

args.each {|option, value|
    case option
    
    when '--maxmind'
        host = 'maxmind'

    when '--ip2location'
        host = 'ip2location'

    end
}

ip = ARGV.shift

if !ip || ip.empty?
    $stderr.puts "Usage: #{$0} <ip>"
    exit 1
elsif !ip.match(/(\d{1,3}\.){3}\d{1,3}/)
    if !(ip = Resolv.getaddress(ip) rescue nil)
        $stderr.puts "That dosn't look like an IP to me."
        exit 2
    end
elsif ip.split(/\./).any? {|block| block.to_i > 255}
    $stderr.puts "Are you trying to kid me? >:("
    exit 3
end

case host

when 'maxmind'
    data = Net::HTTP.get(URI.parse("http://www.maxmind.com/app/locate_demo_ip?ips=#{ip}")).match(%r{MaxMind GeoIP City/ISP/Organization Edition Results.*?<table>.*?<tr>.*?<tr>(.*?)</tr>}m)[1]
    data = data.scan(%r{<font size="-1">(.*?)</font>})
    data = data.map {|item|
        item = item.shift

        if !item || item.empty?
            item = '-'
        end
        
        item
    }

    data = [data[2], data[4], data[5], data[7], data[8], data[6], '-', '-', data[9], (Resolv.getname(ip) rescue nil)]

when 'ip2location'
    data = Net::HTTP.get(URI.parse("http://www.ip2location.com/#{ip}")).match(%r{<span id="dgLookup__ctl2_lblICountry">(.*?)</span>.*?<span id="dgLookup__ctl2_lblIRegion">(.*?)</span>.*?<span id="dgLookup__ctl2_lblICity">(.*?)</span>.*?<span id="dgLookup__ctl2_lblILatitude">(.*?)</span>.*?<span id="dgLookup__ctl2_lblILongitude">(.*?)</span>.*?<span id="dgLookup__ctl2_lblIZIPCode">(.*?)</span>.*?<span id="dgLookup__ctl2_lblITimeZone">(.*?)</span>.*?<span id="dgLookup__ctl2_lblINetSpeed">(.*?)</span>.*?<span id="dgLookup__ctl2_lblIISP">(.*?)</span>.*?<span id="dgLookup__ctl2_lblIDomain">(.*?)</span>}m).to_a
    data.shift

end

country, region, city, latitude, longitude, zip, timezone, netSpeed, isp, domain = data

puts <<DATA
Country:   #{country}
Region:    #{region}
City:      #{city}
Latitude:  #{latitude}
Longitude: #{longitude}
ZIP Code:  #{zip}

Net Speed: #{netSpeed}
ISP:       #{isp}
Domain:    #{domain}
DATA
