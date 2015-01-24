module Helpers
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

  # using this in no-javascript authentication method
  def access_token_from_cookie
    #authenticator.get_user_info_from_cookies(request.cookies)['access_token']
    #authenticator
    redirect authenticator.url_for_oauth_code(:permissions => FACEBOOK_SCOPE)
  rescue => err
    warn err.message
  end

  def access_token
    puts "SESSION_ACCESS_TOKEN_COOKIE from helper = #{request.cookies['access_token']}"
    session[:access_token] = request.cookies['access_token']
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
end