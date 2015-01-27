require 'mongo'
include Mongo
require 'date'

# mongolab configuration
mongo_uri = "mongodb://heroku_app32513773:43e9143cv2j1j4d9v4opirieqj@ds027751.mongolab.com:27751/heroku_app32513773"
db_name = mongo_uri[%r{/([^/\?]+)(\?|$)}, 1]
client = MongoClient.from_uri(mongo_uri)
@db = client.db(db_name)

# puts db.collection('users').find_one({'id' => 2}).nil?
#
# insert_retval = db.collection('users').insert({'id' => 2})
# puts insert_retval

# ja_tmps = db.collection('users').find_one({'graph_id' => '967156229980171'})['timestamps']
# puts "ja_tmps = #{ja_tmps}"
# puts "ja_tmps kao DateTime = #{DateTime.parse(ja_tmps.to_s)}"
#
# time = DateTime.parse(ja_tmps.to_s).to_time
# puts "Stariji od 3 dana = #{!time.to_i.between?(Time.now.to_i - (3*24*60*60), Time.now.to_i)}"

# Collects all categories from all the likes
# @return [Array] all categories in DB
# def prepare_categories
#   category_a = []
#
#   @db.collection('likes').find().each do |like|
#     like['likes_data'].each do |u_like|
#       unless u_like['category_list'].nil?
#         u_like['category_list'].each do |category|
#           category_a << category['name']
#         end
#       else
#         category_a << u_like['category']
#       end
#     end
#   end
#
#   category_a
#
# end
#
# puts "sve kategorije su: #{prepare_categories}"

cat = ["jedan", "dva", "tri", "cetiri"]
u_cat = ["jedAn", "dVa", "Tri", "dvA", "cetIri", "cetiri", "DvA"]

# u_vector = cat.map do |category|
#   category = u_cat.count {|u_category| u_category.downcase == category.downcase}
# end
#
# puts u_vector.to_s

#puts @db.collection('users').remove({'id' => 2})

# Collects all categories from all the likes
# @return [Array] all categories in DB
def prepare_categories
  categories_a = []

  @db.collection('likes').find().each do |like|
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

  @db.collection('likes').find().each do |like|

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

    puts "For #{like['graph_id']} u_vector = #{u_vector} \n u_vector.length = #{u_vector.length}"
    # data_vectors.remove({ 'graph_id' => like['user_graph_id'] })
    # data_vectors.insert({ 'graph_id' => like['user_graph_id'], 'data_vector' =>  u_vector.to_s })

  end

end

# vector

# res = prepare_categories
# puts "categories_list = #{res}"
# puts "categories_list.length = #{res.length}"

#puts @db.collection('likes').find().select {|rec| rec['user_graph_id'] == "967156229980171"}

# def same_likes(id_1, id_2)
#
#   likes_1 = @db.collection('likes').find().select {|rec| rec['user_graph_id'] == id_1.to_s}
#   likes_2 = @db.collection('likes').find().select {|rec| rec['user_graph_id'] == id_2.to_s}
#
#   puts "liekes_1.class = #{likes_1[0]['likes_data']}"
#   puts likes_2
#
#   likes_1['likes_data'] & likes_2['likes_data']
#
# end
#
# puts same_likes(967156229980171, 967156229980171)

# h1 = [{'njnja' => 0.21}, {'ono' => 0.321}, {'lop' => 0.91}, {'kome' => 0.43}]
# puts h1[0]
# h1.sort! { |a, b| b.values[0].to_f <=> a.values[0].to_f }
# puts h1[0]
#
# a_arr = [1,2,3,4,5,6]
# puts a_arr.take(10)

likes_1 = @db.collection('likes').find().select {|rec| rec['user_graph_id'] == 978625438818675.to_s}
likes_2 = @db.collection('likes').find().select {|rec| rec['user_graph_id'] == 967156229980171.to_s}


# puts "likes_1 = #{likes_1[0]['likes_data']}"
# puts "likes_2 = #{likes_2[0]['likes_data'][10].class}"

puts "intersect: #{likes_1[0]['likes_data'] & likes_2[0]['likes_data']}"

inter = []
likes_1[0]['likes_data'].each do |l1|
  likes_2[0]['likes_data'].each do |l2|
    inter << l1 if l1['id'].to_i == l2['id'].to_i
  end
end

puts "inter = #{inter}"

#puts likes_2.include?( {"category"=>"Musician/band", "name"=>"Third Gallery", "created_time"=>"2013-09-04T18:48:30+0000", "id"=>"42648158335"} )

