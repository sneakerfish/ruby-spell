require "test_helper"

class SpellingControllerTest < ActionDispatch::IntegrationTest
  setup do
    Word.import(%w[ elephant elegant relevant ])
  end

  test "shows the search form" do
    get root_path

    assert_response :success
    assert_select "form input[name=word]"
    assert_select ".results", count: 0
  end

  test "suggests corrections for a misspelled word" do
    get root_path(word: "elephent")

    assert_response :success
    assert_select ".verdict.incorrect", /not in the dictionary/
    assert_select "tbody tr:first-child td", text: "elephant"
  end

  test "confirms a correctly spelled word" do
    get root_path(word: "Elephant")

    assert_select ".verdict.correct", /spelled correctly/
  end

  test "check returns JSON suggestions" do
    get "/check", params: { word: "elephent" }

    assert_response :success
    body = response.parsed_body
    assert_equal "elephent", body["word"]
    assert_equal false, body["found"]
    assert_equal({ "spelling" => "elephant", "distance" => 1 }, body["suggestions"].first)
  end

  test "check requires a word" do
    get "/check"

    assert_response :bad_request
    assert_match "word", response.parsed_body["error"]
  end

  test "rejects overly long input" do
    get "/check", params: { word: "a" * 100 }

    assert_response :unprocessable_content
  end

  test "ngrams returns the trigrams of a word" do
    get "/ngrams", params: { word: "cat" }

    assert_equal({ "word" => "cat", "ngrams" => %w[ *ca cat at* ] }, response.parsed_body)
  end

  test "levenshtein returns the edit distance" do
    get "/levenshtein", params: { worda: "kitten", wordb: "sitting" }

    assert_equal 3, response.parsed_body["distance"]
  end
end
