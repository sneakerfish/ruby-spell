# A correctly spelled dictionary word.
#
# Every word is stored together with its trigrams (see Trigrams). To suggest
# corrections for a possibly misspelled term we:
#
#   1. find every dictionary word that shares at least one trigram with it, then
#   2. rank those candidates by Levenshtein distance (the number of single-letter
#      insertions, deletions or substitutions needed to turn one into the other),
#      computed by PostgreSQL's fuzzystrmatch extension.
class Word < ApplicationRecord
  MAX_LENGTH = 40

  has_many :ngrams, dependent: :delete_all

  normalizes :spelling, with: ->(spelling) { spelling.strip.downcase }
  validates :spelling, presence: true, uniqueness: true, length: { maximum: MAX_LENGTH }

  after_save :index_trigrams, if: :saved_change_to_spelling?

  # Words ranked by how close they are to +term+, closest first. Each returned
  # Word has an extra +distance+ attribute holding its Levenshtein distance.
  def self.suggestions_for(term, limit: 10)
    term = term.to_s.strip.downcase
    candidate_ids = Ngram.where(ngram: Trigrams.of(term)).select(:word_id)

    select(:id, :spelling)
      .select(sanitize_sql_array([ "levenshtein(words.spelling, ?) AS distance", term ]))
      .where(id: candidate_ids)
      .order("distance", :spelling)
      .limit(limit)
  end

  # Levenshtein distance between any two strings, calculated by PostgreSQL.
  def self.levenshtein(a, b)
    connection.select_value(sanitize_sql_array([ "SELECT levenshtein(?, ?)", a.to_s, b.to_s ]))
  end

  # Fast bulk loader for big word lists (one INSERT per batch instead of one
  # per word). Words that are already in the dictionary are skipped, so it is
  # safe to run more than once. Returns the number of words added.
  def self.import(spellings, batch_size: 1_000)
    spellings = spellings.map { |s| s.to_s.strip.downcase }
                         .reject { |s| s.empty? || s.length > MAX_LENGTH }
                         .uniq

    spellings.each_slice(batch_size).sum do |batch|
      transaction do
        added = insert_all(batch.map { |spelling| { spelling: } },
                           unique_by: :spelling, returning: %i[id spelling])
        ngram_rows = added.flat_map do |row|
          Trigrams.of(row["spelling"]).map { |ngram| { word_id: row["id"], ngram: } }
        end
        Ngram.insert_all(ngram_rows) if ngram_rows.any?
        added.length
      end
    end
  end

  private
    def index_trigrams
      ngrams.delete_all
      ngrams.insert_all(Trigrams.of(spelling).map { |ngram| { ngram: } })
    end
end
