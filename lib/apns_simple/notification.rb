require 'json'

module ApnsSimple
  class Notification

    PAYLOAD_MAX_BYTESIZE = 2048

    attr_reader :payload
    attr_accessor :error, :error_message, :error_code

    def initialize(options, custom_payload = {})
      token = options.fetch(:token)
      alert = options[:alert]
      badge = options[:badge]
      sound = options[:sound] || 'default'
      content_available = options[:content_available]

      payload_hash = { aps: {} }
      payload_hash[:aps][:alert] = alert if alert
      payload_hash[:aps][:badge] = badge if badge
      payload_hash[:aps][:sound] = sound if sound
      payload_hash[:aps]['content-available'] = 1 if content_available
      payload_hash.merge! custom_payload

      packed_token = [token.gsub(/[<\s>]/,'')].pack('H*')
      packed_message = payload_hash.to_json.gsub(/\\u([\da-fA-F]{4})/) {|m| [$1].pack("H*").unpack("n*").pack("U*")}
      payload_size = packed_message.bytesize

      if payload_size > PAYLOAD_MAX_BYTESIZE
        self.error = true
        self.error_message = "Payload size is #{payload_size} bytes but maximum #{PAYLOAD_MAX_BYTESIZE} bytes allowed."
      end

      self.payload = [0, 0, 32, packed_token, 0, payload_size, packed_message].pack("ccca*cca*")
    end

  end
end