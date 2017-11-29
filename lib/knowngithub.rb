require 'ipaddr'
require 'json'
require 'net/http'
require 'uri'

require 'net/ssh'
require 'nokogiri'
require "knowngithub/version"

module Knowngithub
  def self.safe_call(url)
    uri = URI.parse(url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_PEER

    request = Net::HTTP::Get.new(uri.request_uri)

    http.request(request)
  end

  def self.fingerprints
    pattern = /^(sha256:[a-z0-9\+\/]{43})|([0-9a-f\:]{32,47})$/i
    res = self.safe_call('https://help.github.com/articles/github-s-ssh-key-fingerprints/')
    output = Nokogiri::HTML(res.body)
    fields = output.xpath("//code")
    return fields.children.map(&:content).select{ |x| pattern =~ x }
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
    h = self.host
    return [ h["host_as_string"], h["ssh_type"], h["base64_key"] ].join(' ')
  end

  def self.known_hosts
    h = self.host
    cidr_ranges = JSON.parse(self.safe_call('https://api.github.com/meta').body)["git"]
    known_hosts = []
    cidr_ranges.each do |range|
      IPAddr.new(range).to_range.to_a.map { |a| a.to_s }.each do |ip|
        known_hosts << 'github.com,' + ip + ' ' + h["base64_key"]
      end
    end
    return known_hosts
  end
end
