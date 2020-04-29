# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require_relative 'config/application'

Rails.application.load_tasks
include  ActionView::Helpers::DateHelper

desc "Load fuzzy string match extension (do after db:create)"
task :load_fuzzy => [:environment] do
  ActiveRecord::Base.connection.execute("create extension fuzzystrmatch")
end

desc "Load dictionary file"
task :load_dictionary => [:environment] do
  beginning_time = Time.now
  File.readlines("#{Rails.root}/words_alpha.txt").each_with_index do |line, ndx|
    word = line.chomp
    Word.create(spelling: word)
    if ndx % 1000 == 0
      puts "#{word}: #{ndx} words indexed in #{time_ago_in_words(beginning_time)}."
    end
  end
end
