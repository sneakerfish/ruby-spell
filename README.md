# Ruby Spell

A small Ruby on Rails app that checks spelling and suggests corrections.
It is a companion to [express-spell](https://github.com/sneakerfish/express-spell)
and [python-spell](https://github.com/sneakerfish/python-spell), which
implement the same idea in Node and Python.

![Rails 8.1](https://img.shields.io/badge/Rails-8.1-red) ![Ruby 3.4](https://img.shields.io/badge/Ruby-3.4-red)

## How it works

Spell checking combines two algorithms:

1. **N-gram (trigram) decomposition.** Every dictionary word is broken into
   the three-letter fragments it contains, with a `*` added at each end so the
   start and end of the word count too. `cat` becomes `*ca`, `cat`, `at*`.
   These are stored in the `ngrams` table. To check a word we break it up the
   same way and find every dictionary word that shares at least one trigram
   with it. That quickly narrows hundreds of thousands of words down to a
   few thousand plausible candidates.
2. **Levenshtein distance.** The candidates are ranked by edit distance: the
   number of single-letter insertions, deletions or substitutions needed to
   turn one word into the other. `elefant` → `elephant` is 2 (f→p, insert h).
   PostgreSQL computes it with the `levenshtein()` function from its
   [`fuzzystrmatch`](https://www.postgresql.org/docs/current/fuzzystrmatch.html)
   extension.

Where to look in the code:

| File | What it does |
| --- | --- |
| [`lib/trigrams.rb`](lib/trigrams.rb) | Splits a word into trigrams |
| [`app/models/word.rb`](app/models/word.rb) | Dictionary words, trigram indexing, `Word.suggestions_for` |
| [`app/models/ngram.rb`](app/models/ngram.rb) | One trigram belonging to a word |
| [`app/controllers/spelling_controller.rb`](app/controllers/spelling_controller.rb) | The web page and the JSON API |
| [`app/views/spelling/check.html.erb`](app/views/spelling/check.html.erb) | The search form and results |
| [`db/migrate/`](db/migrate) | Tables, indexes and the `fuzzystrmatch` extension |
| [`lib/tasks/dictionary.rake`](lib/tasks/dictionary.rake) | Loads a large word list |

## Running with Docker (easiest)

All you need is [Docker](https://docs.docker.com/get-docker/).

```sh
docker compose up
```

Then open <http://localhost:3000>. The first start installs gems and creates
the database, and seeds it with a small sample dictionary
([`db/dictionary/sample_words.txt`](db/dictionary/sample_words.txt)).

Other useful commands:

```sh
docker compose run --rm web bin/rails test      # run the tests
docker compose run --rm web bin/rails console   # poke at the models
docker compose down                             # stop (add -v to delete the database too)
```

## Running locally

Requirements:

* Ruby 3.4 (see [`.ruby-version`](.ruby-version))
* PostgreSQL 13 or newer, including the contrib extensions (they ship with
  the standard PostgreSQL packages, Postgres.app and Homebrew's `postgresql`)

```sh
bundle install
bin/rails db:prepare   # creates the databases, runs migrations and loads the sample words
bin/rails server
```

By default Rails connects to PostgreSQL through the local socket as your
operating system user. To use a different server or user, set the standard
PostgreSQL environment variables, for example:

```sh
export PGHOST=localhost PGUSER=postgres PGPASSWORD=postgres
```

`bin/setup` does all of the above in one step and starts the server.

## Loading a full dictionary

The sample dictionary only has a couple of hundred words. For real results,
load a big word list with one word per line, such as `words_alpha.txt`
(~370,000 words) from [dwyl/english-words](https://github.com/dwyl/english-words):

```sh
curl -LO https://raw.githubusercontent.com/dwyl/english-words/master/words_alpha.txt
bin/rails dictionary:load                     # reads ./words_alpha.txt
bin/rails "dictionary:load[/path/to/words]"   # or any other file
```

With Docker, put the file in the project directory and run
`docker compose run --rm web bin/rails dictionary:load`.

Loading is idempotent (words already in the dictionary are skipped) and
takes about a minute.

## JSON API

The same endpoints as the sibling projects:

| Request | Response |
| --- | --- |
| `GET /check?word=elefant` | `{"word":"elefant","found":false,"suggestions":[{"spelling":"elegant","distance":1}, ...]}` |
| `GET /ngrams?word=cat` | `{"word":"cat","ngrams":["*ca","cat","at*"]}` |
| `GET /levenshtein?worda=kitten&wordb=sitting` | `{"worda":"kitten","wordb":"sitting","distance":3}` |

Missing parameters return `400`, and words longer than 40 characters return `422`.

## Tests and checks

```sh
bin/rails test   # unit, model and controller tests
bin/ci           # setup, security audits (bundler-audit, Brakeman) and tests
```

## Deploying

This is a demo, but it runs in production like any Rails app: set
`RAILS_ENV=production`, `SECRET_KEY_BASE` (generate one with
`bin/rails secret`) and `DATABASE_URL`, then run `bin/rails assets:precompile`
and `bin/rails db:prepare`, and start the server behind an HTTPS proxy.
