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

puts @db.collection('users').remove({'id' => 2})


