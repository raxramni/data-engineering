require 'openid'
require 'openid/store/filesystem'

def openid_consumer
  @openid_consumer ||= OpenID::Consumer.new(session,
      OpenID::Store::Filesystem.new("/tmp/openid"))
end

def root_url
  request.url.match(/(^.*\/{2}[^\/]*)/)[1]
end
