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

    session[:user_id] = @user['id']

  end

  erb :index

end

get "/calculate" do

  # # srecnije resenje
  # # dodati jos timestamps user-u pa ga redirektovati na '/' ako su suvise stari njegovi podaci
  # # user treba u data_utils da se upisuje poslednji
  while settings.db.collection("users").find_one({'graph_id' => session[:user_id]}).nil?
    puts settings.db.collection("users").find_one({'graph_id' => session[:user_id]})
    puts "CEKAM DA SE UPISE #{session[:user_id]}"
    next
  end

  # if session[:user_id] is set show data
  # if not redirect user to '/'

  "<p>Under construction</p>"
end

# used by Canvas apps - redirect the POST to be a regular GET
post "/" do
  redirect "/"
end

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