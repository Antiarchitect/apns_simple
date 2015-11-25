require 'openssl'
require 'socket'

module ApnsSimple
  class Client

    attr_reader :certificate, :passphrase, :host, :port

    COMMAND = 8
    CODES = {
      0 => 'No errors encountered',
      1 => 'Processing error',
      2 => 'Missing device token',
      3 => 'Missing topic',
      4 => 'Missing payload',
      5 => 'Invalid token size',
      6 => 'Invalid topic size',
      7 => 'Invalid payload size',
      8 => 'Invalid token',
      10 => 'Shutdown',
      255 => 'Unknown error'
    }

    def initialize(options)
      @certificate = options.fetch(:certificate)
      @passphrase = options[:passphrase] || ''
      gateway_uri = options[:gateway_uri] || 'apn://gateway.push.apple.com:2195'
      @host, @port = parse_gateway_uri(gateway_uri)
    end

    def push(notification)
      begin
        ctx = OpenSSL::SSL::SSLContext.new
        ctx.ssl_version = :TLSv1
        ctx.key = OpenSSL::PKey::RSA.new(certificate, passphrase)
        ctx.cert = OpenSSL::X509::Certificate.new(certificate)

        sock = TCPSocket.new(host, port)
        ssl = OpenSSL::SSL::SSLSocket.new(sock, ctx)
        ssl.connect
        ssl.write(notification.payload)
        ssl.flush

        if IO.select([ssl], nil, nil, 1) && error = ssl.read(6)
          command, status, _index = error.unpack("ccN")
          notification.error = command == COMMAND ? "#{status}: #{CODES[status]}" : "Unknown command received from APNS server: #{command}"
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