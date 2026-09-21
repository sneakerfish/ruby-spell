require "test_helper"

class WordTest < ActiveSupport::TestCase
  setup do
    Word.import(%w[ elephant elegant relevant eleven cat ])
  end

  test "saving a word stores its trigrams" do
    word = Word.create!(spelling: "Dog")

    assert_equal "dog", word.spelling
    assert_equal %w[ *do dog og* ], word.ngrams.pluck(:ngram).sort
  end

  test "changing the spelling rebuilds the trigrams" do
    word = Word.create!(spelling: "dog")
    word.update!(spelling: "dig")

    assert_equal %w[ *di dig ig* ], word.ngrams.pluck(:ngram).sort
  end

  test "spellings are unique and limited in length" do
    assert_not Word.new(spelling: "cat").valid?
    assert_not Word.new(spelling: "a" * 41).valid?
    assert_not Word.new(spelling: " ").valid?
  end

  test "import adds new words with trigrams and skips duplicates" do
    assert_equal 1, Word.import(%w[ cat Cat mouse ])
    assert_equal %w[ *mo mou ous se* use ], Word.find_by!(spelling: "mouse").ngrams.pluck(:ngram).sort
  end

  test "suggestions are ranked by Levenshtein distance" do
    suggestions = Word.suggestions_for("elephent")

    assert_equal "elephant", suggestions.first.spelling
    assert_equal 1, suggestions.first.distance
    assert_equal suggestions.map(&:distance).sort, suggestions.map(&:distance)
    assert_not_includes suggestions.map(&:spelling), "cat"
  end

  test "a correctly spelled word is its own best suggestion" do
    assert_equal [ "elephant", 0 ], Word.suggestions_for("Elephant").first.then { [ it.spelling, it.distance ] }
  end

  test "input is safely escaped in SQL" do
    assert_nothing_raised { Word.suggestions_for("o'neil'); drop table words; --").to_a }
    assert Word.table_exists?
  end

  test "levenshtein distance" do
    assert_equal 1, Word.levenshtein("cat", "cut")
    assert_equal 3, Word.levenshtein("kitten", "sitting")
  end
end
