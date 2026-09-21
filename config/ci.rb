# Run using bin/ci

CI.run do
  step "Setup", "bin/setup --skip-server"

  step "Security: Gem audit", "bundle exec bundler-audit check --update"
  step "Security: Brakeman code analysis", "bundle exec brakeman --quiet --no-pager --exit-on-warn --exit-on-error"

  step "Tests: Rails", "bin/rails test"
  step "Tests: Seeds", "env RAILS_ENV=test bin/rails db:seed:replant"
end
