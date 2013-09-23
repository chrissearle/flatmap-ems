require 'sinatra'
require 'json'
require 'mongo'

include Mongo

if (settings.environment == :development)
  HOST = "http://localhost:9292"

  client = MongoClient.new('localhost', '27017')
  db = client.db('test')
else
  HOST = "http://flatmap-ems.herokuapp.com"

  mongo_uri = ENV['MONGOLAB_URI']
  db_name = mongo_uri[%r{/([^/\?]+)(\?|$)}, 1]
  client = MongoClient.from_uri(mongo_uri)
  db = client.db(db_name)
end

get '/static/EMS-Config.plist' do
  content_type 'application/xml', :charset => 'utf-8'
  send_file File.join(settings.root, 'static/EMS-Config.plist')
end

get '/events' do
  data = {
    :collection => {
      :version => "1.0",
      :href => "#{HOST}/events",
      :items => []
    }
  }
  
  events = db["events"]
  
  events.find.each do |event|
    data[:collection][:items] << {
      :href => "#{HOST}/events/#{event['slug']}",
      :name => event["name"],
      :data => [
        {
          :name => "name",
          :value => event["name"]
        },
        {
          :name => "slug",
          :value => event["slug"]
        },
        {
          :name => "venue",
          :value => event["venue"]
        }
      ],
      :links => [
        {
            :href => "#{HOST}/events/#{event['slug']}/sessions",
            :rel => "session collection",
            :count => 0 # session count
        },
        {
            :href => "#{HOST}/events/#{event['slug']}/slots",
            :rel => "slot collection"
        },
        {
            :href => "#{HOST}/events/#{event['slug']}/slots",
            :rel => "room collection"
        }
      ]
    }
  end
  
  
  send_data data
end

get '/' do
  data = {
    :collection => {
      :version => "1.0",
      :href => "#{HOST}/",
      :links => [
        {
          :href => "#{HOST}/events",
          :rel => "event collection",
        }
      ]
    }
  }
  
  send_data data
end


def send_data(data)
  content_type 'application/vnd.collection+json', :charset => 'utf-8'
  
  data.to_json
end
