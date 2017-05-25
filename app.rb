require 'bundler'
Bundler.require
require 'json'
require 'cgi'
require 'digest/md5'

REDIS = ENV['REDIS_URL'] ? Redis.new(url: ENV['REDIS_URL']) : Redis.new()

def slack name: "omankoxxx", icon: "https://pbs.twimg.com/profile_images/570938224/omankoxxx_400x400.png", channel: "", text: ""
  url = "https://slack.com/api/chat.postMessage?token=#{ENV['SLACK_TOKEN']}&channel=%23#{channel}&text=#{text}&username=#{name}&link_names=1&pretty=1&icon_url=#{CGI.escape(icon)}"
  RestClient.get(url)
end

def new? str
  key = "omankoxxx-#{Digest::MD5.hexdigest(str)}"
  unless REDIS.get(key)
    yield
    REDIS.set(key, "done")
  end
end

JSON.parse(RestClient.get("https://pawoo.net/api/v1/timelines/public?local=true&media=true").body).each{|x|
  if x['sensitive']
    new?(x['url']){
      slack(channel: ENV['CHANNEL'], text: x['url'])
      x['media_attachments'].map{|m| m['url'] }.each{|m|
        slack(channel: ENV['CHANNEL'], text: m)
      }
    }
  end
}
