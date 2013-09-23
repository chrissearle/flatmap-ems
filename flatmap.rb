require 'sinatra'
require 'sinatra/json'
require 'sinatra/url_for'
require 'mongo'

include Mongo

if settings.environment == :development
  client = MongoClient.new('localhost', '27017')
  db = client.db('test')
else
  mongo_uri = ENV['MONGOLAB_URI']
  db_name = mongo_uri[%r{/([^/\?]+)(\?|$)}, 1]
  client = MongoClient.from_uri(mongo_uri)
  db = client.db(db_name)
end

get '/static/EMS-Config.plist' do
  content_type 'application/xml', :charset => 'utf-8'
  send_file File.join(settings.root, 'static/EMS-Config.plist')
end

get '/events/:slug/sessions' do
  send_collection('/', {})
end

get '/events/:slug/slots' do
  send_collection('/', {})
end

get '/events/:slug/rooms' do
  send_collection('/', {})
end

get '/events/:slug' do
  events(db["events"].find("slug" => params[:slug]))
end

get '/events' do
  events(db["events"])
end

get '/' do
  send_collection("/",
                  {:links =>
                       [
                           {
                               :href => url_for("/events", :full),
                               :rel => "event collection",
                           }
                       ]
                  })
end

def events(events)
  data = {:items => []}

  events.find.each do |event|
    data[:items] << {
        :href => url_for("/events/#{event['slug']}", :full),
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
                :href => url_for("/events/#{event['slug']}/sessions", :full),
                :rel => "session collection",
                :count => 0 # session count
            },
            {
                :href => url_for("/events/#{event['slug']}/slots", :full),
                :rel => "slot collection"
            },
            {
                :href => url_for("/events/#{event['slug']}/rooms", :full),
                :rel => "room collection"
            }
        ]
    }
  end


  send_collection url_for("/events", :full), data
end


def send_collection(href, data)
  content_type 'application/vnd.collection+json', :charset => 'utf-8'

  data[:version] = "1.0"
  data[:href] = url_for(href, :full)

  json ({:collection => data})
end
