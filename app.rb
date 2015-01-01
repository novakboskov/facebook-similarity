require "sinatra"
require 'koala'
require 'mongo'
include Mongo
require './modules/data_utils'
include DataUtils

enable :sessions
set :raise_errors, true
set :show_exceptions, false

configure do
  # mongolab configuration
  mongo_uri = ENV['MONGOLAB_URI']
  db_name = mongo_uri[%r{/([^/\?]+)(\?|$)}, 1]
  client = MongoClient.from_uri(mongo_uri)
  set :db, client.db(db_name)
end

# enable foreman to write on stdout non buffered way
$stdout.sync = true

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

helpers do
  def host
    request.env['HTTP_HOST']
  end

  def scheme
    request.scheme
  end

  def url_no_scheme(path = '')
    "//#{host}#{path}"
  end

  def url(path = '')
    "#{scheme}://#{host}#{path}"
  end

  def authenticator
    @authenticator ||= Koala::Facebook::OAuth.new(ENV["FACEBOOK_APP_ID"], ENV["FACEBOOK_SECRET"], url("/auth/facebook/callback"))
  end

  # allow for javascript authentication
  def access_token_from_cookie
    #authenticator.get_user_info_from_cookies(request.cookies)['access_token']
    #authenticator
    redirect authenticator.url_for_oauth_code(:permissions => FACEBOOK_SCOPE)
  rescue => err
    warn err.message
  end

  def access_token
    session[:access_token] || access_token_from_cookie
  end

end

# the facebook session expired! reset ours and restart the process
error(Koala::Facebook::APIError) do
  puts "ERROR IS " + env['sinatra.error'].message
  session[:access_token] = nil
  redirect "/auth/facebook"
end

get "/" do

  # Get base API Connection
  @graph  = Koala::Facebook::API.new(access_token, ENV["FACEBOOK_SECRET"])

  # Get public details of current application
  @app  =  @graph.get_object(ENV["FACEBOOK_APP_ID"])

  if access_token

    @user    = @graph.get_object("me")
    @friends = @graph.get_connections('me', 'friends')
    @photos  = @graph.get_connections('me', 'photos')
    @likes   = @graph.get_connections('me', 'likes')

    puts "Ovo su lajkovi:\n"
    @likes.each do |like|
      puts like
    end

    @data_thread = Thread.new do
      write_collections(@user, access_token, @friends, @photos, @likes)
    end

  end

  erb :index

end

get "/calculate" do
  @data_thread.join
  # Show algorithm results to the user
end

# used by Canvas apps - redirect the POST to be a regular GET
post "/" do
  redirect "/"
end

# used to close the browser window opened to post to wall/send to friends
get "/close" do
  "<body onload='window.close();'/>"
end

# Doesn't actually sign out permanently, but good for testing
get "/preview/logged_out" do
  session[:access_token] = nil
  request.cookies.keys.each { |key, value| response.set_cookie(key, '') }
  redirect '/'
end

# Allows for direct oauth authentication
# koristi se samo kada je API error
get "/auth/facebook" do
  session[:access_token] = nil
  redirect authenticator.url_for_oauth_code(:permissions => FACEBOOK_SCOPE)
end

get '/auth/facebook/callback' do
  session[:access_token] = authenticator.get_access_token(params[:code])
  redirect '/'
end

get "/privacypolicy" do
  File.new('public/privacypolicy.htm').readlines
end