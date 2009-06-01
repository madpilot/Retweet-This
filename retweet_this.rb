require 'rubygems'
require 'twitter'
require 'yaml'

class RetweetThis
  def setup(consumer_token = nil, consumer_secret = nil)
    unless consumer_token && consumer_secret
      puts "1. Goto http://twitter.com/oauth_clients/new"
      puts "2. Hit Enter once you have filled in the details"
      STDIN.gets
      unless consumer_token
        puts "3 .Enter the consumer token that was generated"
        consumer_token = STDIN.gets
      end
      unless consumer_secret
        puts "4. Enter the consumer secret that was generated"
        consumer_secret = STDIN.gets
      end
    end
    
    File.open(".retweet_this", "w") do |out| 
      YAML.dump({ 
        :consumer_token => consumer_token, 
        :consumer_secret => consumer_secret 
      }, out)
    end

    begin
      oauth = Twitter::OAuth.new(consumer_token, consumer_secret)
    rescue OAuth::Unauthorized
      puts "Unauthorised"
      exit(1)
    end

    puts "5. Cut and past this into your browser: " + oauth.request_token.authorize_url
    puts "6. Click Allow, once that has happened, hit Enter"
     
    STDIN.gets
   
    begin
      oauth.authorize_from_request(oauth.request_token.token, oauth.request_token.secret)
    rescue OAuth::Unauthorized
      puts "Unauthorised"
      exit(1)
    end
    
    File.open(".retweet_this", "w") do |out| 
      YAML.dump({
        :consumer_token => consumer_token, 
        :consumer_secret => consumer_secret, 
        :access_token => oauth.access_token.token,
        :access_secret => oauth.access_token.secret
      }, out)
    end

    puts "OK, OAuth is setup, we are good to go. Run this program again with no arguments."
  end

  def read_settings
    settings = {
      :consumer_token => nil,
      :consumer_secret => nil,
      :access_token => nil,
      :access_secret => nil
    }
    settings.merge!(YAML.load_file('.retweet_this')) if File.exist?('.retweet_this')
    settings
  end

  def run
    settings = read_settings
    case(ARGV[0])
    when "setup"
      self.setup(ARGV[1] || settings[:consumer_token], ARGV[2] || settings[:consumer_secret])
    else
      self.setup(settings[:consumer_token], settings[:consumer_secret]) unless settings[:access_token] && settings[:access_secret]
      self.fetch
    end
  end

  def fetch
    settings = read_settings
    oauth = Twitter::OAuth.new(settings[:consumer_token], settings[:consumer_secret])
    oauth.authorize_from_access(settings[:access_token], settings[:access_secret])
    client = Twitter::Base.new(oauth)
    
    client.friends_timeline.each do |tweet|
      # TODO Increment some counters, and if it passes a threshold, kick em to the curb
      puts tweet.user.screen_name + ": " + tweet.text if tweet.text =~ /^RT .*| RT .*/i
    end
  end
end

r = RetweetThis.new()
r.run
