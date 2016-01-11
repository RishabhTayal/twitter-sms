configure :development do
  Bundler.require :development
  Envyable.load("config/env.yml", "development")
end

# use Rack::TwilioWebhookAuthentication, ENV["TWILIO_AUTH_TOKEN"], "/messages"

post "/messages" do
  puts "webhook called" 
  p params
  p request.body.read
  @body = JSON.parse(request.body)
  p @body
  # p request.body.read[:message_data]["bodies"][0]["content"]
  # twitter.update(params["Body"]) #if params["From"] == ENV["MY_PHONE_NUMBER"]
  # content_type "text/xml"
  # "<Response/>"
end

get "/health" do
  200
end

def twitter
  @twitter ||= Twitter::REST::Client.new do |config|
    config.consumer_key        = ENV["TWITTER_CONSUMER_KEY"]
    config.consumer_secret     = ENV["TWITTER_CONSUMER_SECRET"]
    config.access_token        = ENV["TWITTER_ACCESS_TOKEN"]
    config.access_token_secret = ENV["TWITTER_ACCESS_SECRET"]
  end
end

EM.schedule do
  TweetStream.configure do |config|
    config.consumer_key        = ENV["TWITTER_CONSUMER_KEY"]
    config.consumer_secret     = ENV["TWITTER_CONSUMER_SECRET"]
    config.oauth_token         = ENV["TWITTER_ACCESS_TOKEN"]
    config.oauth_token_secret  = ENV["TWITTER_ACCESS_SECRET"]
  end

  client = TweetStream::Client.new

  client.on_direct_message do |direct_message|
    if direct_message.sender.screen_name != ENV["TWITTER_USERNAME"]
      send_sms("DM from #{direct_message.sender.screen_name}: #{direct_message.text}")
    end
  end

  client.on_timeline_status do |status|
    if status.user_mentions.any? { |mention| mention.screen_name == ENV["TWITTER_USERNAME"] }
      send_sms("@mention from #{status.user.screen_name}: #{status.text}")
    end
  end

  client.userstream
end
