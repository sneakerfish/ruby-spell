# The spell checker needs PostgreSQL's fuzzystrmatch extension (which provides
# levenshtein()), plus indexes so trigram lookups stay fast once a full
# dictionary of ~370k words is loaded.
class AddFuzzyMatchingAndIndexes < ActiveRecord::Migration[8.1]
  def change
    enable_extension "fuzzystrmatch"

    add_index :words, :spelling, unique: true
    add_index :ngrams, :ngram
    add_index :ngrams, :word_id
    add_foreign_key :ngrams, :words, on_delete: :cascade
  end
end
