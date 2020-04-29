require 'trigrams'

class Word < ActiveRecord::Base
  has_many :ngrams
  before_save :add_word

  def add_word
    self.ngrams.destroy_all
    trigrams(self.spelling).each do |ng|
      self.ngrams << Ngram.new(:ngram => ng)
    end
  end

  def self.locate(word)
    word_grams = trigrams(word)
    wordgrams_string = word_grams.map {|w| "\'" + w + "\'" }.join(", ")
    sql = "select distinct words.id, words.spelling, " +
          "levenshtein(\'#{word}\', words.spelling) as ld " +
          "from ngrams, words " +
          "where ngrams.word_id = words.id " +
          "and ngrams.ngram in (#{wordgrams_string}) " +
          "order by ld limit 30"
    puts sql
    ActiveRecord::Base.connection.execute(sql)
      .collect {|i| [i["spelling"], i["ld"]] }
      .sort {|j,k| [j[1],j[0]] <=> [k[1], k[0]] }[0..30]
  end
end
