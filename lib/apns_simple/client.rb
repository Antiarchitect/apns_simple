require 'openssl'
require 'socket'

module ApnsSimple
  class Client

    class CertificateActivenessTimeError < StandardError; end

    attr_reader :ssl_context, :host, :port

    DEFAULT_CERTIFICATE_PASSWORD = ''
    DEFAULT_GATEWAY_URI = 'apn://gateway.push.apple.com:2195'
    ERROR_BYTES_COUNT = 6
    COMMAND = 8
    INVALID_TOKEN_CODE = 8
    CODES = {
      0 => 'No errors encountered',
      1 => 'Processing error',
      2 => 'Missing device token',
      3 => 'Missing topic',
      4 => 'Missing payload',
      5 => 'Invalid token size',
      6 => 'Invalid topic size',
      7 => 'Invalid payload size',
      INVALID_TOKEN_CODE => 'Invalid token',
      10 => 'Shutdown',
      255 => 'Unknown error'
    }
    TIMEOUT = 5 # In seconds

    def initialize(options)
      certificate = options.fetch(:certificate)
      current_time = Time.now.utc
      cert = OpenSSL::X509::Certificate.new(certificate)
      if current_time < cert.not_before || current_time > cert.not_after
        raise CertificateActivenessTimeError, "CURRENT_TIME: #{current_time}, NOT_BEFORE: #{cert.not_before}, NOT_AFTER: #{cert.not_after}"
      end

      @ssl_context = OpenSSL::SSL::SSLContext.new
      ssl_context.cert = cert

      passphrase = options[:passphrase] || DEFAULT_CERTIFICATE_PASSWORD
      ssl_context.key = OpenSSL::PKey::RSA.new(certificate, passphrase)
      
      gateway_uri = options[:gateway_uri] || DEFAULT_GATEWAY_URI
      @host, @port = parse_gateway_uri(gateway_uri)
    end

    def push(notification)
      unless notification.error
        begin
          sock = TCPSocket.new(host, port)
          ssl = OpenSSL::SSL::SSLSocket.new(sock, ssl_context)
          ssl.sync = true
          ssl.connect
          ssl.write(notification.payload)

          if (ready = IO.select([ssl], [], [], TIMEOUT))
            readable_ssl_socket = ready.first.first
            if (error = readable_ssl_socket.read(ERROR_BYTES_COUNT))
              command, code, _index = error.unpack('ccN')
              notification.error = true
              if command == COMMAND
                notification.error_code = code
                notification.error_message = "CODE: #{code}, DESCRIPTION: #{CODES[code]}"
              else
                notification.error_message = "Unknown command received from APNS server: #{command}"
              end
            end
          end
        ensure
          ssl.close if ssl
          sock.close if sock
        end
      end
    end

    private

    def parse_gateway_uri(uri)
      first, last = uri.sub('apn://', '').split(':')
      [first, last.to_i]
    end

  end
end