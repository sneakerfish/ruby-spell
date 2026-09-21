require "test_helper"

class TrigramsTest < ActiveSupport::TestCase
  test "a single letter is one trigram padded with stop characters" do
    assert_equal [ "*a*" ], Trigrams.of("a")
  end

  test "two letters" do
    assert_equal [ "*ab", "ab*" ], Trigrams.of("ab")
  end

  test "three letters" do
    assert_equal [ "*ab", "abc", "bc*" ], Trigrams.of("abc")
  end

  test "is case-insensitive" do
    assert_equal Trigrams.of("cat"), Trigrams.of("CaT")
  end

  test "supports a custom stop character" do
    assert_equal [ "$ca", "cat", "at$" ], Trigrams.of("cat", stop_char: "$")
  end
end
