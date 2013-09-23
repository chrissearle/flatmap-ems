require 'sinatra'
require 'json'

get '/static/EMS-Config.plist' do
  content_type 'application/xml', :charset => 'utf-8'
  send_file File.join(settings.root, 'static/EMS-Config.plist')
end

get '/' do
  data = {
    :collection => {
      :version => "1.0",
      :href => "http://flatmap-ems.herokuapp.com/",
      :links => [
        {
          :href => "http://flatmap-ems.herokuapp.com/events",
          :rel => "event collection",
        }
      ]
    }
  }
  
  content_type 'application/vnd.collection+json', :charset => 'utf-8'
  
  data.to_json
end
