require 'json'

module ApnsSimple
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