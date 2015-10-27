require 'json'

module ApnsSimple
  class Notification

    attr_reader :token, :alert, :badge, :sound, :content_available, :custom_payload
    attr_accessor :error

    def initialize(options, custom_payload = {})
      @token = options.fetch(:token)
      @alert = options[:alert]
      @badge = options[:badge]
      @sound = options[:sound] || 'default'
      @content_available = options[:content_available]
      @custom_payload = custom_payload
    end

    def payload
      payload = { aps: {} }
      payload[:aps][:alert] = alert if alert
      payload[:aps][:badge] = badge if badge
      payload[:aps][:sound] = sound if sound
      payload[:aps]['content-available'] = 1 if content_available
      payload.merge! custom_payload

      packed_message = payload.to_json.gsub(/\\u([\da-fA-F]{4})/) {|m| [$1].pack("H*").unpack("n*").pack("U*")}
      packed_token = [token.gsub(/[\s|<|>]/,'')].pack('H*')
      [0, 0, 32, packed_token, 0, packed_message.bytesize, packed_message].pack("ccca*cca*")
    end

  end
end