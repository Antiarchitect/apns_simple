require_relative 'apns_simple/client'
require_relative 'apns_simple/notification'
require_relative 'apns_simple/version'

module ApnsSimple
  class CertificateActivenessTimeError < StandardError; end
end
