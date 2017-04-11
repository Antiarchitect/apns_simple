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
      sound = options[:sound]
      content_available = options[:content_available]

      payload_hash = { aps: {} }
      payload_hash[:aps][:alert] = alert if alert
      payload_hash[:aps][:badge] = badge if badge
      payload_hash[:aps][:sound] = sound if sound
      payload_hash[:aps]['content-available'] = 1 if content_available
      payload_hash.merge! custom_payload

      token_item = pack_token_item(token)
      payload_item = pack_payload_item(payload_hash)
      frame = compose_frame(token_item, payload_item)
      @payload = pack_frame(frame)
    end

    private

      def pack_frame(frame)
        [2, frame.bytesize, frame].pack('cNa*')
      end

      def compose_frame(*args)
        args.compact.join
      end

      def pack_token_item(token)
        [1, 32, token.gsub(/[<\s>]/, '')].pack('cnH64')
      end

      def pack_payload_item(hash)
        json = hash.to_json.gsub(/\\u([\da-fA-F]{4})/) { |m| [$1].pack('H*').unpack('n*').pack('U*') }
        size = json.bytesize

        if size > PAYLOAD_MAX_BYTESIZE
          self.error = true
          self.error_message = "Payload size is #{size} bytes but maximum #{PAYLOAD_MAX_BYTESIZE} bytes allowed."
        end

        [2, size, json].pack('cna*')
      end

  end
end