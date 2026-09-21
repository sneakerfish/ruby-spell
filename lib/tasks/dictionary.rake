namespace :dictionary do
  desc "Load a word list (one word per line) into the dictionary. " \
       "Defaults to words_alpha.txt from https://github.com/dwyl/english-words"
  task :load, [ :path ] => :environment do |_task, args|
    path = Pathname(args[:path] || Rails.root.join("words_alpha.txt"))
    abort "Word list not found: #{path}. See README for where to download one." unless path.exist?

    started = Time.current
    added = 0
    File.foreach(path, chomp: true).each_slice(10_000) do |slice|
      added += Word.import(slice)
      puts "#{added} words added (#{(Time.current - started).round(1)}s)..."
    end
    puts "Done. #{Word.count} words in the dictionary."
  end
end
