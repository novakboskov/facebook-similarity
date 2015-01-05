get "/privacypolicy", :provides => 'html' do
  send_file './static/privacypolicy.htm'
end