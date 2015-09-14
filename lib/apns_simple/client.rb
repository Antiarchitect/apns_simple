require 'openssl'
require 'socket'

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
          _command, status, _index = error.unpack("ccN")
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
end