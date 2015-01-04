module DataUtils
  def data_pagination(likes, friends)

    puts "POCEO DATA PAGINATION"

    # likes pagination
    current_likes = likes
    begin
      until current_likes.next_page.nil? do
        likes.concat current_likes.next_page
        current_likes = current_likes.next_page
      end
    rescue Koala::Facebook::APIError => err
      # koala gem github:"arsduo/koala" issue #405
      # error code 2500
      puts "Error Koala pagination [@likes]: " + err.message
    end

    # friends pagination
    current_friends = friends
    begin
      until current_friends.next_page.nil? do
        friends.concat current_friends.next_page
        current_friends = current_friends.next_page
      end
    rescue Koala::Facebook::APIError => err
      # koala gem github:"arsduo/koala" issue #405
      # error code 2500
      puts "Error Koala pagination [@friends]: " + err.message
    end

    puts "GOTOV DATA PAGINATION"

  end

  def write_collections(user, access_token, friends, photos, likes)

    # debug
    if user['name'] =='Новак Бошков'
      sleep 20
      p "Novak ceka 1"
    end

    data_pagination(likes, friends)

    users_coll = settings.db.collection("users")
    likes_coll = settings.db.collection("likes")
    friends_coll = settings.db.collection("friends")
    photos_coll = settings.db.collection("photos")

    # write user

    user_doc = {'name' => user['name'],\
              'graph_id' =>  user['id'],\
              'access_token' => access_token,\
              'link' =>  user['link'],\
              'gender' =>  user['gender'],\
              'inspirational_people' => user['inspirational_people'],\
              'languages' => user['languages']}

    if users_coll.find_one({'graph_id' => user['id']}).nil?
      begin
        users_coll.insert(user_doc)
      rescue Mongo::OperationFailure => mongo_error
        puts 'Error in insert user_doc: ' + mongo_error.message
      end
    end

    puts "GOTOV UPIS USER #{user['name']}"

    # write likes

    likes_array = []
    likes.each { |like| likes_array << like }

    likes_doc = {'user_graph_id' => user['id'], 'likes_data' => likes_array}

    if likes_coll.find_one({'user_graph_id' => user['id']}).nil?
      begin
        likes_coll.insert(likes_doc)
      rescue Mongo::OperationFailure => mongo_error
        puts 'Error in insert likes_doc: ' + mongo_error.message
      end
    end

    puts "GOTOV UPIS LIKES #{user['name']}"

    # write friends

    friends_array = []
    friends.each { |friend| friends_array << friend }

    friends_doc = {'user_graph_id' => user['id'], 'friends_data' => friends_array,\
                    'friends_summary' => friends.raw_response['summary']}

    if friends_coll.find_one({'user_graph_id' => user['id']}).nil?
      begin
        friends_coll.insert(friends_doc)
      rescue Mongo::OperationFailure => mongo_error
        puts 'Error in insert friends_doc: ' + mongo_error.message
      end
    end

    puts "GOTOV UPIS FRIENDS #{user['name']}"

    # write photos

    photos_array = []
    photos.each { |photo| photos_array << photo }

    photos_doc = {'user_graph_id' => user['id'], 'photos_data' => photos_array}

    if photos_coll.find_one({'user_graph_id' => user['id']}).nil?
      begin
        photos_coll.insert(photos_doc)
      rescue Mongo::OperationFailure => mongo_error
        puts 'Error in insert photos_doc: ' + mongo_error.message
      end
    end

    puts "GOTOV UPIS PHOTOS #{user['name']}"

  end
end