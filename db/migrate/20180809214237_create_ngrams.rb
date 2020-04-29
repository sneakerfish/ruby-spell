class CreateNgrams < ActiveRecord::Migration[5.2]
  def change
    create_table :ngrams do |t|
      t.string :ngram, null: false, limit: 3
      t.integer :word_id, null: false
    end
  end
end
