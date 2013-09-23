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

get '/events/:event/slots/:slug' do
  slots(params[:event], db["slots"].find("event" => params[:event], "slug" => params[:slug]))
end

get '/events/:event/slots' do
  slots(params[:event], db["slots"])
end

get '/events/:event/rooms/:slug' do
  rooms(params[:event], db["rooms"].find("event" => params[:event], "slug" => params[:slug]))
end

get '/events/:event/rooms' do
  rooms(params[:event], db["rooms"])
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

def slots(event, slots)
  data = {:items => []}

  slots.find.each do |slot|
    data[:items] << {
        :href => url_for("/events/#{event}/slots/#{slot['slug']}", :full),
        :data => [
            {
                :start => slot['start'].strftime("%FT%T%:Z").gsub(/UTC/, "Z"),
                :end => slot['end'].strftime("%FT%T%:Z").gsub(/UTC/, "Z")
            }
        ]
    }
  end

  send_collection url_for("/events/#{event}/slots", :full), data
end

def rooms(event, rooms)
  data = {:items => []}

  rooms.find.each do |room|
    data[:items] << {
        :href => url_for("/events/#{event}/rooms/#{room['slug']}", :full),
        :data => [
            { :name => room['name'] }
        ]
    }
  end

  send_collection url_for("/events/#{event}/rooms", :full), data
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
