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
  response.delete_cookie 'access_token' #
  redirect authenticator.url_for_oauth_code(:permissions => FACEBOOK_SCOPE)
end

get '/auth/facebook/callback' do
  puts "REDIRECTED TO CALLBACK FOR AUTHENTICATOR CALLBACK"
  session[:access_token] = authenticator.get_access_token(params[:code])
  response.set_cookie 'access_token', session[:access_token] #
  redirect '/'
end

get '/logout' do
  session[:access_token] = nil
  response.delete_cookie 'access_token'
  redirect '/'
end
