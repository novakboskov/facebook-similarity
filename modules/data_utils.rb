require_relative 'algorithms'
include Algorithms

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

    data_pagination(likes, friends)

    users_coll = settings.db.collection("users")
    likes_coll = settings.db.collection("likes")
    friends_coll = settings.db.collection("friends")
    photos_coll = settings.db.collection("photos")

    # decision to write user data if it's data is too old

    unless users.find_one({'graph_id' => session[:user_id]}).nil?
      actual_timestamps = \
          DateTime.parse users.find_one({'graph_id' => session[:user_id]})['timestamps'].to_s
    end

    # write likes

    likes_array = []
    likes.each { |like| likes_array << like }

    likes_doc = {'user_graph_id' => user['id'], 'likes_data' => likes_array}

    if likes_coll.find_one({'user_graph_id' => user['id']}).nil?\
      || (!actual_timestamps.nil? && !record_fresh?(actual_timestamps))
      begin
        if !actual_timestamps.nil? && !record_fresh?(actual_timestamps)
          likes_coll.update({ 'user_graph_id' => user['id'] }, likes_doc)
        else
          likes_coll.insert(likes_doc)
        end
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

    if friends_coll.find_one({'user_graph_id' => user['id']}).nil?\
      || (!actual_timestamps.nil? && !record_fresh?(actual_timestamps))
      begin
        if !actual_timestamps.nil? && !record_fresh?(actual_timestamps)
          friends_coll.update({ 'user_graph_id' => user['id'] }, friends_doc)
        else
          friends_coll.insert(friends_doc)
        end
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

    # write user

    user_doc = {'name' => user['name'],\
              'graph_id' =>  user['id'],\
              'access_token' => access_token,\
              'link' =>  user['link'],\
              'gender' =>  user['gender'],\
              'inspirational_people' => user['inspirational_people'],\
              'languages' => user['languages'],\
              'data_vector' => '',\
              'timestamps' => DateTime.now.to_s}

    if users_coll.find_one({'graph_id' => user['id']}).nil?\
      || (!actual_timestamps.nil? && !record_fresh?(actual_timestamps))
      begin
        if !actual_timestamps.nil? && !record_fresh?(actual_timestamps)
          users_coll.update({ 'graph_id' => user['id'] }, user_doc)
        else
          users_coll.insert(user_doc)
        end
      rescue Mongo::OperationFailure => mongo_error
        puts 'Error in insert user_doc: ' + mongo_error.message
      end
    end

    puts "GOTOV UPIS USER #{user['name']}"

  end

  # Collects all categories from all the likes
  # @return [Array] all categories in DB
  def prepare_categories
    categories_a = []

    likes.find().each do |like|
      like['likes_data'].each do |u_like|
        unless u_like['category_list'].nil?
          u_like['category_list'].each do |category|
            categories_a << category['name'].downcase unless categories_a.include?(category['name'].downcase)
          end
        else
          categories_a << u_like['category'].downcase unless categories_a.include?(u_like['category'].downcase)
        end
      end
    end

    categories_a.uniq

  end

  # Makes all the users data vectors
  # and write every vector to corresponding collection in DB
  def vector
    categories_a = prepare_categories

    likes.find().each do |like|

      u_categories = []

      like['likes_data'].each do |u_like|
        unless u_like['category_list'].nil?
          u_like['category_list'].each do |category|
            u_categories << category['name']
          end
        else
          u_categories << u_like['category']
        end
      end

      u_vector = categories_a.map do |category|
        category = u_categories.count {|u_category| u_category.downcase == category.downcase}
      end

      data_vectors.remove({ 'graph_id' => like['user_graph_id'] })
      data_vectors.insert({ 'graph_id' => like['user_graph_id'], 'data_vector' =>  u_vector.to_s })

    end

  end

  # Calculates user data based on it's user graph ID
  # @param id [String] Facebook graph API ID of the user stored in database as graph_id
  def calculate(id, type)
    vector
    similar_users = []
    similar_users_info = {}
    actual_user_vector_s = data_vectors.find_one({'graph_id' => id.to_s})['data_vector']
    actual_user_vector = \
        actual_user_vector_s[1, actual_user_vector_s.length-2].split(', ').map {|e| e.to_i}

    puts "ACTUAL USER FROM CALCULATE = #{actual_user_vector}, ID = #{id}"

    data_vectors.find().each do |v|
      unless v['graph_id'] == id.to_s || v['data_vector'].nil? || v['data_vector'] == ''
        u_vector = v['data_vector']
        u_vector_a = u_vector[1, u_vector.length-2].split(', ').map {|e| e.to_i}
        
        if type.to_i == 0
          puts "STANDARD ALGORITHM WORKS"
          similar_users << { v['graph_id'] => pearson_score(actual_user_vector, u_vector_a) }
        elsif type.to_i == 1          
          puts "ALGORITHM COSIN SIMILARITY WORKS"
          likes_actual = likes.find_one({"user_graph_id" => id.to_s})
          likes_user = likes.find_one({"user_graph_id" => v['graph_id']})

          # Jaccard index
          sim_factor = same_likes(id, v['graph_id']).count.to_f / (likes_user['likes_data'].count + likes_actual['likes_data'].count).to_f
          cosine_sim_factor = cosine_similarity(actual_user_vector, u_vector_a)
          cosine_sim_factor = 0 if cosine_sim_factor.nan?
          similar_users << { v['graph_id'] => cosine_sim_factor * sim_factor }
          
          puts "DEBUG upisan #{v['graph_id']} => #{cosine_sim_factor * sim_factor}"
        end

        full_user_info = users.find().select {|rec| rec['graph_id'] == v['graph_id']}
        similar_users_info.merge!( { v['graph_id'] => full_user_info[0] } )
      end

    end

    similar_users.sort! { |a, b| b.values[0].to_f <=> a.values[0].to_f }
    return similar_users, similar_users_info

  end

end
