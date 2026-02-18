# to run
# bin/rails dictionary:rebuild_vocab

# lib/tasks/dictionary.rake
namespace :dictionary do
  task rebuild_vocab: :environment do
    puts "--- Starting Vocab Rebuild ---"

    # 1. Clear the old data
    Sc03Dictionary::DicVocab.delete_all

    # 2. Get the data, rejecting anything where name is blank
    # name.presence ensures that empty strings "" are also treated as nil
    data = Sc03Dictionary::DicEntry.where(is_current: true)
                                   .distinct
                                   .pluck(:name, :lang)
                                   .reject { |name, lang| name.blank? }

    if data.any?
      puts "Filtered out blanks. Processing #{data.size} valid terms..."

      # 3. Process in batches of 5,000 to keep memory low
      data.each_slice(5000) do |batch|
        sql_values = batch.map do |name, lang|
          # Normalize using the model method
          norm_val = Sc03Dictionary::DicVocab.normalize(name)

          # Cap lengths to prevent the B-Tree index error we saw earlier
          safe_name = name.to_s.strip[0..250]
          safe_norm = norm_val[0..250]

          name_esc = ActiveRecord::Base.connection.quote(safe_name)
          lang_esc = ActiveRecord::Base.connection.quote(lang)
          norm_esc = ActiveRecord::Base.connection.quote(safe_norm)

          "(#{lang_esc}, #{name_esc}, #{norm_esc})"
        end.join(", ")

        ActiveRecord::Base.connection.execute(
          "INSERT INTO sc_03_dictionary.dic_vocab (lang, term, term_norm) VALUES #{sql_values}"
        )
        print "." # Progress indicator
      end

      puts "\nSuccess! Indexed #{data.size} terms."
    else
      puts "No valid entries with names found."
    end
  end
end