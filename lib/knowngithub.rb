require 'ipaddr'
require 'json'
require 'net/http'
require 'net/ssh'
require 'nokogiri'
require 'open-uri'
require "knowngithub/version"

module Knowngithub
  def self.fingerprints
    output = Nokogiri::HTML(open("https://help.github.com/articles/github-s-ssh-key-fingerprints/"))
    fields = output.xpath("//code")
    return fields.children.map(&:content)
  end

  def self.session
    s = Net::SSH::Transport::Session.new('github.com', { :verify_host_key => true })
    s.close
    s
  end

  def self.host
    s = self.session
    if self.fingerprints.any?{|f| f == s.host_keys.first.fingerprint}
      base64_key = [Net::SSH::Buffer.from(:key, s.host_keys.first).to_s].pack("m*").gsub(/\s/, "")
      return {
        "host_as_string" => s.host_as_string,
        "ssh_type" => s.host_keys.first.ssh_type,
        "base64_key" => base64_key
      }
    else
      raise SecurityError # while this is inappropriate, it sounds cool
    end
  end

  def self.known_host
    host = self.host
    return [ host["host_as_string"], host["ssh_type"], host["base64_key"] ].join('')
  end

  def self.known_hosts
    host = self.host
    cidr_ranges = JSON.parse(Net::HTTP.get(URI('https://api.github.com/meta')))["git"]
    known_hosts = []
    cidr_ranges.each do |range|
      IPAddr.new(range).to_range.to_a.map { |a| a.to_s }.each do |ip|
        known_hosts << 'github.com,' + ip + ' ' + host["base64_key"]
      end
    end
    return known_hosts
  end
end
