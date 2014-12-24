require "sinatra"
require 'koala'
require 'mongo'
include Mongo

enable :sessions
set :raise_errors, false
set :show_exceptions, false

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
    begin
    @authenticator ||= Koala::Facebook::OAuth.new(ENV["FACEBOOK_APP_ID"], ENV["FACEBOOK_SECRET"], url("/auth/facebook/callback"))
    rescue Koala::Facebook::APIError => api_err
      puts "_____- greska u authenticator________\n" + api_err.fb_error_message
    end
  end

  puts "--------------------------------------------------SADA DEFINISE HELPER access_token_from_cookie--------------------------------------------------"
  # allow for javascript authentication
  def access_token_from_cookie
    #authenticator.get_user_info_from_cookies(request.cookies)['access_token']
    puts "_______________ SACE ZOVE AUTHENTICATOR __________________"
    authenticator
    #session['oauth'] ||= Koala::Facebook::OAuth.new(ENV["FACEBOOK_APP_ID"], ENV["FACEBOOK_SECRET"])
    # redirect to facebook to get your code
    #puts "_____________________ SADA TREBA DA REDIREKTUJEM NA URL FOR OAUTH CODE_______________________"
    #redirect session['oauth'].url_for_oauth_code()
  rescue Koala::Facebook::APIError => api_err
    puts "__________ access_token_from_cookie, Koala::Facebook::APIError ________________\n api_err.http_status \n" + api_err.http_status.nil? + "\n api_err = \n" + api_err.message
  rescue => err
    warn err.message
    puts "________________OTISAO NA ERR_________________"
  end

  def access_token
    token_string = ''
    token_string ||= session[:access_token]
    puts "SADA TREBA DA UZME ACCESS TOKEN U access_token helperu, access_token = " + token_string
    session[:access_token] || access_token_from_cookie
  end

end

# the facebook session expired! reset ours and restart the process
error(Koala::Facebook::APIError) do
  puts "-------------------------------------------------- API Error --------------------------------------------------"
  session[:access_token] = nil
  redirect "/auth/facebook"
end

get "/" do
  # testiram mongo bazu
  mongo_uri = ENV['MONGOLAB_URI']
  db_name = mongo_uri[%r{/([^/\?]+)(\?|$)}, 1]
  client = MongoClient.from_uri(mongo_uri)
  db = client.db(db_name)
  #db.collection_names.each { |name| puts name + ' OVO JE KOLEKCIJA'}

  # Get base API Connection
  puts "--------------------------------------------------SADA TREBA DA DOBIJE GRAPH TOKENOM --------------------------------------------------"
  begin
    @graph  = Koala::Facebook::API.new(access_token)
  rescue Koala::Facebook::APIError => api_err
    puts "__________ / , Koala::Facebook::APIError ________________\n api_err.http_status \n" + api_err.http_status.nil? + "\n api_err = \n" + api_err.message
  end

  # Get public details of current application
  @app  =  @graph.get_object(ENV["FACEBOOK_APP_ID"])

  if access_token
    @user    = @graph.get_object("me")
    @friends = @graph.get_connections('me', 'friends')
    @photos  = @graph.get_connections('me', 'photos')
    @likes   = @graph.get_connections('me', 'likes')

    puts "--------------------------------------------------SADA TREBA DA ISPISE LIKES--------------------------------------------------"

    i = 0
    @likes.each do |item|
      i += 1
      puts "Like[#{i}] = " + item + "\n"
    end
    ii = 0
    @friends.each do |friend|
      puts "friend[#{ii}] = " + friend + "\n"
    end

    # for other data you can always run fql
    @friends_using_app = @graph.fql_query("SELECT uid, name, is_app_user, pic_square FROM user WHERE uid in (SELECT uid2 FROM friend WHERE uid1 = me()) AND is_app_user = 1")
  end

  erb :index

end

# ovo pogoditi da se trigeruje racunanje
get "/calculate" do
  erb :calculate
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

=begin
# Allows for direct oauth authentication
get "/auth/facebook" do
  #session[:access_token] = nil
  puts "-------------------------------------------------- /auth/facebook --------------------------------------------------"
  #redirect authenticator.url_for_oauth_code(:permissions => FACEBOOK_SCOPE)
  redirect session['oauth'].url_for_oauth_code(:permissions => FACEBOOK_SCOPE)
end
=end

get "/auth/facebook" do
  begin
    redirect authenticator.url_for_oauth_code(:permissions => FACEBOOK_SCOPE)
  rescue Koala::Facebook::APIError => api_err
    puts "_____ - greska u /auth/facebook _______\n" + api_err.fb_error_message
  end
  token_string = ''
  token_string ||= session[:access_token]
  puts 'U AUTH/FACEBOOK/CALLBACK , access_token = ' + token_string
  #redirect '/'
end

get "/auth/facebook/callback" do
  begin
    session[:access_token] = authenticator.get_access_token(params[:code]
  rescue Koala::Facebook::APIError => api_err
    puts "_____ - greska u /auth/facebook/callback _______\n" + api_err.fb_error_message
  end
  #redirect '/'
end

=begin
# Benben's solution
get '/' do
  if session['access_token']
    'You are logged in! <a href="/logout">Logout</a>'
    # do some stuff with facebook here
    # for example:
    @graph = Koala::Facebook::API.new(session["access_token"])
    # publish to your wall (if you have the permissions)
    # @graph.put_wall_post("I'm posting from my new cool app!")
    # or publish to someone else (if you have the permissions too ;) )
    # @graph.put_wall_post("Checkout my new cool app!", {}, "someoneelse's id")

    @likes = @graph.get_connections('me', 'likes')
    i = 0
    @likes.each do |item|
      i += 1
      puts "Like[#{i}] = " + item + "\n"
    end

  else
    '<a href="/login">Login</a>'
  end
end

get '/login' do
  # generate a new oauth object with your app data and your callback url
  session['oauth'] = Koala::Facebook::OAuth.new(ENV["FACEBOOK_APP_ID"], ENV["FACEBOOK_SECRET"], "#{request.base_url}/callback")
  # redirect to facebook to get your code
  redirect session['oauth'].url_for_oauth_code()
end

get '/logout' do
  session['oauth'] = nil
  session['access_token'] = nil
  redirect '/'
end

#method to handle the redirect from facebook back to you
get '/callback' do
  #get the access token from facebook with your code
  session['access_token'] = session['oauth'].get_access_token(params[:code])
  redirect '/'
end

get "/auth/facebook" do
  redirect session['oauth'].url_for_oauth_code(:permissions => FACEBOOK_SCOPE)
end
=end
