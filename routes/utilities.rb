require_relative '../modules/data_utils'
include DataUtils

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

    data_thread = Thread.new do
      write_collections(@user, access_token, @friends, @photos, @likes)
    end

    session[:user_id] = @user['id']

  end

  erb :index

end

get "/calculate" do

  # if session[:user_id] is set show data
  # if not redirect user to '/'

  # read calculated data for the corresponding user to some @user_calculated_data
  # visualize it with some erb

  "<p>Under construction</p>"
end

# used by Canvas apps - redirect the POST to be a regular GET
post "/" do
  redirect "/"
end

before '/calculate' do
  # srecnije resenje
  # dodati jos timestamps user-u pa ga redirektovati na '/' ako su suvise stari njegovi podaci
  # user treba u data_utils da se upisuje poslednji
  while users.find_one({'graph_id' => session[:user_id]}).nil?
    puts users.find_one({'graph_id' => session[:user_id]})
    puts "CEKAM DA SE UPISE #{session[:user_id]}"
    next
  end
end

# after filter is blocking load :index
# after '/' do
#   write_collections(@user, access_token, @friends, @photos, @likes)
# end