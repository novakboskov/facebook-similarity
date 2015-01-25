require "sinatra"
require 'koala'
require 'mongo'
include Mongo
require './helpers/helpers'
require 'date'

# enable foreman to write on stdout non buffered way
$stdout.sync = true

configure do

  enable :sessions
  set :session_secret, 'something secret'
  set :raise_errors, true
  set :show_exceptions, false
  set :long_lived_token_max_time, 259200
  set :record_active_days, 3

  # mongolab configuration
  mongo_uri = ENV['MONGOLAB_URI']
  db_name = mongo_uri[%r{/([^/\?]+)(\?|$)}, 1]
  client = MongoClient.from_uri(mongo_uri)
  set :db, client.db(db_name)

end

helpers Helpers

# Scope defines what permissions that we are asking the user to grant.
# In this example, we are asking for the ability to publish stories
# about using the app, access to what the user likes, and to be able
# to use their pictures.  You should rewrite this scope with whatever
# permissions your app needs.
# See https://developers.facebook.com/docs/reference/api/permissions/
# for a full list of permissions

Koala.config.api_version = "v2.2"

FACEBOOK_SCOPE = 'user_likes, user_friends'

unless ENV["FACEBOOK_APP_ID"] && ENV["FACEBOOK_SECRET"]
  abort("missing env vars: please set FACEBOOK_APP_ID and FACEBOOK_SECRET with your app credentials")
end

before do
  # HTTPS redirect
  if settings.environment == :production && request.scheme != 'https'
    redirect "https://#{request.env['HTTP_HOST']}"
  end
end

# the facebook session expired! reset ours and restart the process
error(Koala::Facebook::APIError) do
  puts "ERROR IS " + env['sinatra.error'].message

  if env['sinatra.error'].fb_error_code.to_s == '190' && env['sinatra.error'].fb_error_subcode.to_s == '466'
    # Error validating access token: The session was invalidated explicitly using an API call
    session[:access_token] = nil
    response.delete_cookie 'access_token'
    redirect '/'
  else
    session[:access_token] = nil
    redirect "/auth/facebook"
  end
end

require_relative 'routes/init'