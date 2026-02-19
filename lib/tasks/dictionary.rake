#  bin/rails dictionary:rebuild_search_index

# lib/tasks/dictionary.rake
#
namespace :dictionary do

  task rebuild_search_index: :environment do

    puts "--- Starting Search Index Rebuild ---"

    # 1. Clear the old data
    # Note: Using the new class name we discussed
    Sc03Dictionary::DicSearchIndex.delete_all

    # 2. Get Name, Lang, AND ID
    # We need the ID to populate the fk_entry_id bridge
    data = Sc03Dictionary::DicEntry.where(is_current: true)
                                   .where.not(name: [nil, ""]) # SQL-level rejection
                                   .select(:name, :lang, :fk_index_id)
                                   .group(:name, :lang, :fk_index_id)
                                   .pluck(:name, :lang, :fk_index_id)

    if data.any?
      puts "Found #{data.size} unique term-index pairs. Processing..."

      # 3. Process in batches
      data.each_slice(5000) do |batch|
        sql_values = batch.map do |name, lang, fk_id|
          norm_val = Sc03Dictionary::DicSearchIndex.normalize(name)

          name_esc = ActiveRecord::Base.connection.quote(name.to_s.strip[0..250])
          lang_esc = ActiveRecord::Base.connection.quote(lang)
          norm_esc = ActiveRecord::Base.connection.quote(norm_val[0..250])
          fk_esc   = ActiveRecord::Base.connection.quote(fk_id)

          "(#{lang_esc}, #{name_esc}, #{norm_esc}, #{fk_esc})"
        end.join(", ")

        ActiveRecord::Base.connection.execute(
          "INSERT INTO sc_03_dictionary.dic_search_indexes
          (lang, term, term_norm, fk_index_id)
          VALUES #{sql_values}
          ON CONFLICT (term, lang, fk_index_id) DO NOTHING"
        )
        print "."
      end

      puts "\nSuccess! Indexed #{data.size} terms."
    else
      puts "No valid entries with names found."
    end
  end
end