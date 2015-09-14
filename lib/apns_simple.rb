require 'openssl'
require 'socket'
require 'json'

require_relative 'apns_simple/version'

module ApnsSimple
  class Client

    attr_reader :certificate, :passphrase, :host, :port

    def initialize(options)
      @certificate = options.fetch(:certificate)
      @passphrase = options[:passphrase] || ''
      gateway_uri = options[:gateway_uri] || 'apn://gateway.push.apple.com:2195'
      @host, @port = parse_gateway_uri(gateway_uri)
    end

    def push(notification)
      begin
        ctx = OpenSSL::SSL::SSLContext.new
        ctx.key = OpenSSL::PKey::RSA.new(certificate, passphrase)
        ctx.cert = OpenSSL::X509::Certificate.new(certificate)

        sock = TCPSocket.new(host, port)
        ssl = OpenSSL::SSL::SSLSocket.new(sock, ctx)
        ssl.connect
        ssl.write(notification.payload)
        ssl.flush

        if IO.select([ssl], nil, nil, 1) && error = ssl.read(6)
          command, status, index = error.unpack("ccN")
          notification.error = status
        end
      ensure
        ssl.close if ssl
        sock.close if sock
      end
    end

    private

      def parse_gateway_uri(uri)
        first, last = uri.sub('apn://', '').split(':')
        [first, last.to_i]
      end

  end

  class Notification

    attr_reader :token, :alert, :badge, :sound, :content_available
    attr_accessor :error

    def initialize(options)
      @token = options.fetch(:token)
      @alert = options[:alert]
      @badge = options[:badge]
      @sound = options[:sound] || 'default'
      @content_available = options[:content_available]
    end

    def payload
      payload = { aps: {} }
      payload[:aps][:alert] = alert if alert
      payload[:aps][:badge] = badge if badge
      payload[:aps][:sound] = sound if sound
      payload[:aps][:content_available] = 1 if content_available

      packed_message = payload.to_json.gsub(/\\u([\da-fA-F]{4})/) {|m| [$1].pack("H*").unpack("n*").pack("U*")}
      packed_token = [token.gsub(/[\s|<|>]/,'')].pack('H*')
      [0, 0, 32, packed_token, 0, packed_message.bytesize, packed_message].pack("ccca*cca*")
    end

  end
end
