require 'ipaddr'
require 'json'
require 'net/http'
require 'uri'

require 'net/ssh'
require 'nokogiri'
require 'knowngithub/version'

module Knowngithub
  # Make a call enforcing the strict use of SSL.
  # @param [String] url A full url like `https://help.github.com`
  # @return [Net::HTTP] Return the full Net::HTTP object of the response.
  # @since 0.1.0
  def self.safe_call(url)
    uri = URI.parse(url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_PEER

    request = Net::HTTP::Get.new(uri.request_uri)

    http.request(request)
  end

  # Queries and parses the GitHub help page for the SSH key fingerprints.
  # @return [Array<String>] SSH key fingerprints as an array of strings.
  # @since 1.0.0
  def self.fingerprints
    pattern = /^(sha256:[a-z0-9\+\/]{43})|([0-9a-f\:]{32,47})$/i
    res = safe_call('https://help.github.com/en/articles/githubs-ssh-key-fingerprints')

    output = Nokogiri::HTML(res.body)
    fields = output.xpath('//code')
    fields.children.map(&:content).select { |x| pattern =~ x }
  end

  # Instantiates a Net::SSH session with GitHub to get the host key and closes it.
  # @return [Net:SSH] Returns a closed Net::SSH session
  # @since 0.1.0
  def self.session
    s = Net::SSH::Transport::Session.new('github.com', verify_host_key: true)
    s.close
    s
  end

  # Composes a hash with the properties required for composing a known host entry
  # @return [Hash] Returns a hash object with all of the needed components to compose a `known_hosts` file
  # @raise [SecurityError] If the host keys fail validation or if the https call fails, this will be raised.
  # @since 0.1.0
  def self.host
    s = session
    if fingerprints.any? { |f| f == s.host_keys.first.fingerprint }
      base64_key = [Net::SSH::Buffer.from(:key, s.host_keys.first).to_s].pack('m*').gsub(/\s/, '')
      return {
        'host_as_string' => s.host_as_string,
        'ssh_type' => s.host_keys.first.ssh_type,
        'base64_key' => base64_key
      }
    else
      raise SecurityError # while this is inappropriate, it sounds cool
    end
  end

  # Composes a known_hosts entry for the fqdn only
  # @return [String] Returns a `known_hosts` entry for the fqdn only with no ip address binding as a string.
  # @since 0.1.0
  def self.known_host
    h = host
    [h['host_as_string'], h['ssh_type'], h['base64_key']].join(' ')
  end

  # Calls the `/meta` endpoint on GitHub's API via a safe https call and composes an array of entries ready for appending to a known_hosts file.
  # @return [Array<String>] Returns an array of strings enunciating `known_hosts` entries for every known IP GitHub may serve SSH on.
  # @since 0.1.0
  def self.known_hosts
    h = host
    cidr_ranges = JSON.parse(safe_call('https://api.github.com/meta').body)['git']
    known_hosts = []
    cidr_ranges.each do |range|
      IPAddr.new(range).to_range.to_a.map(&:to_s).each do |ip|
        known_hosts << ["github.com,#{ip}", h['ssh_type'], h['base64_key']].join(' ')
      end
    end
    known_hosts
  end
end
