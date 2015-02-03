require_relative '../modules/data_utils'
include DataUtils

get "/" do

  if access_token

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

  end

  erb :index

end

get "/calculate" do

  @user = users.find_one({'graph_id' => session[:user_id]})

  @similar_users, @similar_users_info = calculate session[:user_id]

  puts "SIMILAR_USERS_INFO = #{@similar_users_info}"
  puts "SIMILAR USERS ARE : #{@similar_users}"

  erb :calculate
end

# used by Canvas apps - redirect the POST to be a regular GET
post "/" do
  redirect "/"
end

before '/calculate' do

  unless session[:user_id]
    # hit calculate directly
    puts "/calculate BUT NO session[:user_id], GO REDIRECT TO /"
    redirect '/'
  end

  # srecnije resenje
  # dodati jos timestamps user-u pa ga redirektovati na '/' ako su suvise stari njegovi podaci
  # user treba u data_utils da se upisuje poslednji
  while users.find_one({'graph_id' => session[:user_id]}).nil?
    puts users.find_one({'graph_id' => session[:user_id]})
    puts "CEKAM DA SE UPISE #{session[:user_id]}"
    next
  end

  puts "SAD DEO O STAROSTI"
  unless users.find_one({'graph_id' => session[:user_id]}).nil?
    # user exists in DB but his record is old one
    # wait to actual thread write new one

    user_timestamps = \
      DateTime.parse users.find_one({'graph_id' => session[:user_id]})['timestamps'].to_s

    puts "PROVERAVAM STAROST ZAPISA O #{session[:user_id]}"

    while !record_fresh?(user_timestamps)
      puts "ZAPIS O #{session[:user_id]} JE SUVISE STAR, CEKAM DA UPISE NOVI"
      begin
        user_timestamps = \
          DateTime.parse users.find_one({'graph_id' => session[:user_id]})['timestamps'].to_s

        puts "NOVI USER_TIMESTAMPS ZA #{session[:user_id]} JE #{user_timestamps.to_s}"
      rescue
        # when this code tries to read user but thread was deleted it and not yet updated it

        next
      end

      next
    end

  end

end