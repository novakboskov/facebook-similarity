module DataUtils
  def write_collections(db, user, friends, photos, likes)
    users_coll = db.collection("users")
    likes_coll = db.collection("likes")
    friends_coll = db.collection("friends")
    photos_coll = db.collection("photos")

    # write user

    user_doc = {'name' => user['name'],\
              'graph_id' =>  user['id'],\
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

  end
end