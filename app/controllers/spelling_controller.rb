class SpellingController < ApplicationController
  # The longest input we accept. levenshtein() in PostgreSQL refuses strings
  # longer than 255 characters, and no dictionary word is longer than this.
  MAX_INPUT_LENGTH = Word::MAX_LENGTH

  before_action :reject_long_input

  rescue_from ActionController::ParameterMissing do |error|
    render json: { error: error.message }, status: :bad_request
  end

  # GET /?word=elefant        (HTML page with a form)
  # GET /check?word=elefant   (JSON)
  def check
    @word = params[:word].to_s.strip.downcase

    respond_to do |format|
      format.html do
        if @word.present?
          @found = Word.exists?(spelling: @word)
          @suggestions = Word.suggestions_for(@word)
        end
      end

      format.json do
        params.require(:word)
        render json: {
          word: @word,
          found: Word.exists?(spelling: @word),
          suggestions: Word.suggestions_for(@word).map { |w| { spelling: w.spelling, distance: w.distance } }
        }
      end
    end
  end

  # GET /ngrams?word=elephant
  def ngrams
    word = params.require(:word)
    render json: { word:, ngrams: Trigrams.of(word) }
  end

  # GET /levenshtein?worda=cat&wordb=cut
  def levenshtein
    worda, wordb = params.require(%i[worda wordb])
    render json: { worda:, wordb:, distance: Word.levenshtein(worda, wordb) }
  end

  private
    def reject_long_input
      too_long = params.values_at(:word, :worda, :wordb).any? { |value| value.to_s.length > MAX_INPUT_LENGTH }
      return unless too_long

      message = "Words can be at most #{MAX_INPUT_LENGTH} characters long."
      respond_to do |format|
        format.html { redirect_to root_path, alert: message }
        format.json { render json: { error: message }, status: :unprocessable_content }
      end
    end
end
