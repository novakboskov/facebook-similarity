require "sinatra"
require 'koala'
require 'mongo'
include Mongo
require './modules/data_utils'
include DataUtils
require './helpers/helpers'

# enable foreman to write on stdout non buffered way
$stdout.sync = true

configure do

  enable :sessions
  set :session_secret, 'something secret'
  set :raise_errors, true
  set :show_exceptions, false

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

FACEBOOK_SCOPE = 'user_likes,user_photos,user_friends'

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
  session[:access_token] = nil
  redirect "/auth/facebook"
end


require_relative 'routes/init'

# get "/" do
#
#   # Get base API Connection
#   @graph  = Koala::Facebook::API.new(access_token, ENV["FACEBOOK_SECRET"])
#
#   # Get public details of current application
#   @app  =  @graph.get_object(ENV["FACEBOOK_APP_ID"])
#
#   if access_token
#
#     @user    = @graph.get_object("me")
#     @friends = @graph.get_connections('me', 'friends')
#     @photos  = @graph.get_connections('me', 'photos')
#     @likes   = @graph.get_connections('me', 'likes')
#
#     puts "Ovo su lajkovi:\n"
#     @likes.each do |like|
#       puts like
#     end
#
#     # @data_thread = Thread.new do
#     #   write_collections(@user, access_token, @friends, @photos, @likes)
#     # end
#
#     session[:user_id] = @user['id']
#
#   end
#
#   erb :index
#
# end

# get "/calculate" do
#
#   # # srecnije resenje
#   # # dodati jos timestamps user-u pa ga redirektovati na '/' ako su suvise stari njegovi podaci
#   # # user treba u data_utils da se upisuje poslednji
#   while settings.db.collection("users").find_one({'graph_id' => session[:user_id]}).nil?
#     puts settings.db.collection("users").find_one({'graph_id' => session[:user_id]})
#     puts "CEKAM DA SE UPISE #{session[:user_id]}"
#     next
#   end
#
#   # if session[:user_id] is set show data
#   # if not redirect user to '/'
#
#   "<p>Under construction</p>"
# end
#
# # used by Canvas apps - redirect the POST to be a regular GET
# post "/" do
#   redirect "/"
# end

# # used to close the browser window opened to post to wall/send to friends
# get "/close" do
#   "<body onload='window.close();'/>"
# end
#
# # Doesn't actually sign out permanently, but good for testing
# get "/preview/logged_out" do
#   session[:access_token] = nil
#   request.cookies.keys.each { |key, value| response.set_cookie(key, '') }
#   redirect '/'
# end
#
# # Allows for direct oauth authentication
# # koristi se samo kada je API error
# get "/auth/facebook" do
#   session[:access_token] = nil
#   redirect authenticator.url_for_oauth_code(:permissions => FACEBOOK_SCOPE)
# end
#
# get '/auth/facebook/callback' do
#   session[:access_token] = authenticator.get_access_token(params[:code])
#   redirect '/'
# end

# get "/privacypolicy", :provides => 'html' do
#   send_file './static/privacypolicy.htm'
# end
#
# before '/calculate' do
#   while settings.db.collection("users").find_one({'graph_id' => session[:user_id]}).nil?
#     puts settings.db.collection("users").find_one({'graph_id' => session[:user_id]})
#     puts "CEKAM DA SE UPISE #{session[:user_id]}"
#     next
#   end
# end
#
# after '/' do
#   write_collections(@user, access_token, @friends, @photos, @likes)
# end