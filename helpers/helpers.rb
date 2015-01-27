module Helpers

  def record_fresh?(date_time)
    time = DateTime.parse(date_time.to_s).to_time
    time.to_i.between?(Time.now.to_i - (settings.record_active_days*24*60*60), Time.now.to_i)
  end

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

  def authenticator_no_redirect
    @authenticator_no_redirect ||= Koala::Facebook::OAuth.new(ENV["FACEBOOK_APP_ID"], ENV["FACEBOOK_SECRET"])
  end

  # using this in no-javascript authentication method
  def access_token_from_cookie
    #authenticator.get_user_info_from_cookies(request.cookies)['access_token']
    #authenticator
    redirect authenticator.url_for_oauth_code(:permissions => FACEBOOK_SCOPE)
  rescue => err
    warn err.message
  end

  def access_token
    if session[:access_token]
      # access_token_is present exchange it for an long lived
      # and put it in session and cookies
      exchanged_token_info = authenticator_no_redirect.exchange_access_token_info request.cookies['access_token']
      puts "EXCHANGED_TOKEN_INFO EXPIRES = #{exchanged_token_info['expires']}"
      response.delete_cookie 'access_token'
      response.set_cookie 'access_token', exchanged_token_info['access_token']
      session[:access_token] = exchanged_token_info['access_token']
    else
      # access_token is not present
      session[:access_token] = request.cookies['access_token']
    end

  end

  def users
    settings.db.collection("users")
  end

  def likes
    settings.db.collection("likes")
  end

  def friends
    settings.db.collection("friends")
  end

  def data_vectors
    settings.db.collection("data_vectors")
  end

  def same_likes(id_1, id_2)

    likes_1 = likes.find().select {|rec| rec['user_graph_id'] == id_1.to_s}
    likes_2 = likes.find().select {|rec| rec['user_graph_id'] == id_2.to_s}

    likes_1[0]['likes_data'] & likes_2[0]['likes_data']

  end

end