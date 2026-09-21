# Loads a small sample dictionary so the app works out of the box.
#
#   bin/rails db:seed
#
# For a real dictionary (~370,000 English words) see `bin/rails dictionary:load`
# in lib/tasks/dictionary.rake.
sample = Rails.root.join("db/dictionary/sample_words.txt")
added = Word.import(File.readlines(sample, chomp: true))
puts "Seeded #{added} words from #{sample.basename} (#{Word.count} in dictionary)."
