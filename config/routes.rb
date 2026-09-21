Rails.application.routes.draw do
  # The spell checker page. Submitting the form is a plain GET, so results are
  # bookmarkable: /?word=elefant
  root "spelling#check"

  # A small JSON API, matching the sibling express-spell and python-spell demos.
  #   GET /check?word=elefant             suggestions for a (mis)spelled word
  #   GET /ngrams?word=elephant           the trigrams a word is broken into
  #   GET /levenshtein?worda=cat&wordb=cut  edit distance between two words
  defaults format: :json do
    get "check" => "spelling#check"
    get "ngrams" => "spelling#ngrams"
    get "levenshtein" => "spelling#levenshtein"
  end

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check
end
