# One trigram (three-letter fragment) of a dictionary word. See Trigrams.
class Ngram < ApplicationRecord
  belongs_to :word
end
