# Breaks a word into its trigrams: every run of three consecutive letters.
#
# A "stop character" is added to both ends first so that the beginning and end
# of the word get trigrams of their own. Two words that share many trigrams are
# probably spelled similarly.
#
#   Trigrams.of("cat")  # => ["*ca", "cat", "at*"]
#   Trigrams.of("a")    # => ["*a*"]
module Trigrams
  STOP_CHAR = "*"

  def self.of(word, stop_char: STOP_CHAR)
    padded = "#{stop_char}#{word.to_s.downcase}#{stop_char}"
    padded.chars.each_cons(3).map(&:join)
  end
end
