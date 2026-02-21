# app/controllers/dictionary/dic/entries_controller.rb
module Dictionary
  module Dic
    class EntriesController < ApplicationController

      def show

        # 1. Get the Pāḷi name from the UUID passed in
        # Rails sees the value in the URL and puts it into the params hash under the key :id
        # gets id from url /dic/entries/4bab8aa8...) to params[:id]
        # Database: SELECT * FROM dic_entry WHERE fk_index_id = '...' LIMIT 1
        # find_by returns one object
        clicked_entry = Sc03Dictionary::DicEntry.find_by(fk_index_id: params[:id])

        # Extracting the Name
        @term_name = clicked_entry&.name

        # if name exists
        if @term_name

          # 2. Find all Pāḷi entries with this name
          # Database: SELECT * FROM dic_entry WHERE name = 'rukkho' AND lang = 'pi'
          pali_entries = Sc03Dictionary::DicEntry.where(name: @term_name, lang: 'pi')

          # 3. For each Pāḷi entry, find its translations (en, lv) sharing the same fk_index_id
          # Plucking the IDs
          # We create a map: { fk_index_id => [array of all entries for that ID] }
          # Result: This is a Simple Array of Strings (UUIDs). ['uuid-1', 'uuid-2', 'uuid-3'...]
          all_related_ids = pali_entries.pluck(:fk_index_id)

          # The Big Final Search & Grouping
          # Database Search: fetches every row (Pāḷi, English, Latvian) for all those UUIDs in one go.
          # The Grouping: This is Ruby magic. It takes that big list and turns it into a Hash (Map)
          @grouped_entries = Sc03Dictionary::DicEntry
                               .includes(:dic_index) # This joins the tables in one/two efficient queries
                               .where(fk_index_id: all_related_ids)
                               .group_by(&:fk_index_id)


          # What actually arrives at the View
          # {
          #   "uuid-123" => [ <Pāḷi Object>, <English Object>, <Latvian Object> ],
          #   "uuid-456" => [ <Pāḷi Object>, <English Object> ],
          #   "uuid-789" => [ <Pāḷi Object>, <Latvian Object> ]
          # }

          # for loop in show.html.erb and outside of loop access
          if @grouped_entries.any?
            # Collect all DicIndex objects from the groups, then find the max date
            all_indices = @grouped_entries.values.flatten.map(&:dic_index).compact
            @latest_date = all_indices.map(&:modified_date).max
          end

        end
      end

      def full

        # 1. Start with the Index (The 'Spine' of the card)
        # 2. Eager load EVERYTHING attached to it across all languages
        @index = Sc03Dictionary::DicIndex.includes(
          dic_entries: [:dic_refs, :dic_notes, :dic_quotes, :dic_egs],
          dic_scans: []
        ).find(params[:id])

        # 3. Organise the entries for easy access in the view
        @all_entries = @index.dic_entries
        @pali_entry  = @all_entries.find { |e| e.lang == 'pi' }
        @translations = @all_entries.reject { |e| e.lang == 'pi' }

        @scans = @index.dic_scans.unscoped
      end


    end
  end
end



#    @entry.modified_by["actor"]["fullname"] # => "Aigars Kokins"
#     @entry.modified_by.dig("change", "reason")

