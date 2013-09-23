require 'sinatra'
require 'sinatra/json'
require 'sinatra/url_for'
require 'mongo'

require 'dalli'
require 'rack-cache'

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
  cache_control :public, max_age: 30 # 30 secs. This is pretty static but if it changes we want to get it fast.
  content_type 'application/xml', :charset => 'utf-8'
  send_file File.join(settings.root, 'static/EMS-Config.plist')
end

get '/events/:event/sessions/:slug/speakers/:speaker' do
end

get '/events/:event/sessions/:slug/speakers' do
  speakers(params[:event], db["sessions"].find("event" => params[:event], "slug" => params[:slug]).first)
end

get '/events/:event/sessions/:slug' do
  sessions(params[:event], db["sessions"].find("event" => params[:event], "slug" => params[:slug]))
end

get '/events/:event/sessions' do
  sessions(params[:event], db["sessions"])
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

def speakers(event, session)
  data = {:items => []}

  session['speakers'].each do |speaker|
    data[:items] << {
        :href => url_for("/events/#{event}/sessions/#{session['slug']}/speakers/#{speaker['slug']}", :full),
        :data => [
            item(:name, speaker['name']),
            item(:bio, speaker['bio'])
        ]
    }
  end

  send_collection url_for("/events/#{event}/sessions/#{session['slug']}/speakers", :full), data
end

def sessions(event, sessions)
  data = {:items => []}

  sessions.find.each do |session|
    item = {
        :href => url_for("/events/#{event}/sessions/#{session['slug']}", :full),
        :data => [
            item(:format, session['format']),
            item(:body, session['body']),
            item(:state, session['state']),
            item(:slug, session['slug']),
            item(:title, session['title']),
            item(:lang, session['language']),
        ],
        :links => [
            rel("speaker collection", url_for("/events/#{event}/sessions/#{session['slug']}/speakers", :full)),
            rel("room item", url_for("/events/#{event}/rooms/#{session['room']}", :full)),
            rel("slot item", url_for("/events/#{event}/slots/#{session['slot']}", :full)),
        ]
    }
    session['speakers'].each do |speaker|
      item[:links] << rel("speaker item", url_for("/events/#{event}/sessions/#{session['slug']}/speakers/#{speaker['slug']}", :full), {:prompt => speaker['name']})
    end

    data[:items] << item
  end

  send_collection url_for("/events/#{event}/sessions", :full), data
end

def slots(event, slots)
  data = {:items => []}

  slots.find.each do |slot|
    data[:items] << {
        :href => url_for("/events/#{event}/slots/#{slot['slug']}", :full),
        :data => [
            item(:start, slot['start'].strftime("%FT%T%:Z").gsub(/UTC/, "Z")),
            item(:end, slot['end'].strftime("%FT%T%:Z").gsub(/UTC/, "Z"))
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
            item(:name, room['name'])
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
            item(:name, event['name']),
            item(:slug, event['slug']),
            item(:venue, event['venue'])
        ],
        :links => [
            rel("session collection", url_for("/events/#{event['slug']}/sessions", :full), {:count => event['count']}), # session count
            rel("slot collection", url_for("/events/#{event['slug']}/slots", :full)),
            rel("room collection", url_for("/events/#{event['slug']}/rooms", :full))
        ]
    }
  end

  send_collection url_for("/events", :full), data
end


def send_collection(href, data)
  cache_control :public, max_age: 1800 # 30 mins.
  content_type 'application/vnd.collection+json', :charset => 'utf-8'

  data[:version] = "1.0"
  data[:href] = url_for(href, :full)

  json ({:collection => data})
end

def item(key, val)
  {
      :name => key,
      :value => val
  }
end

def rel(rel, href, extras = {})
  {
      :rel => rel,
      :href => href
  }.merge(extras)
end