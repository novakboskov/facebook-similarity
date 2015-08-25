module Algorithms

  def pearson_score(a, b)
    n = a.length
    return 0 unless n > 0

    # summing the preferences
    sum1 = a.reduce(0) {|sum, c| sum + c}
    sum2 = b.reduce(0) {|sum, c| sum + c}
    # summing up the squares
    sum1_sq = a.reduce(0) {|sum, c| sum + c ** 2}
    sum2_sq = b.reduce(0) {|sum, c| sum + c ** 2}
    # summing up the product
    prod_sum = a.zip(b).reduce(0) {|sum, ab| sum + ab[0] * ab[1]}

    # calculating the Pearson score
    num = prod_sum - (sum1 *sum2 / n)
    den = Math.sqrt((sum1_sq - (sum1 ** 2) / n) * (sum2_sq - (sum2 ** 2) / n))

    return 0 if den == 0
    return num / den
  end

  def dot_product(a, b)
    products = a.zip(b).map{|a, b| a * b}
    products.reduce(0) {|s,p| s + p}
  end

  def magnitude(point)
    squares = point.map{|x| x ** 2}
    Math.sqrt(squares.reduce(0) {|s, c| s + c})
  end

  # Returns the cosine of the angle between the vectors 
  #associated with 2 points
  #
  # Params:
  #  - a, b: list of coordinates (float or integer)
  #
  def cosine_similarity(a, b)
    dot_product(a, b) / (magnitude(a) * magnitude(b))
  end

end
