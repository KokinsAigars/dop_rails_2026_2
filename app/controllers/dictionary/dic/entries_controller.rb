# app/controllers/dictionary/dic/entries_controller.rb
module Dictionary
  module Dic
    class EntriesController < ApplicationController
      def index
        # Search for the word in the main dictionary
        @entries = Sc03Dictionary::DicEntry.where(name: params[:q], lang: params[:lang], is_current: true)

        if @entries.count == 1
          # Jump straight to the full data
          redirect_to dic_entry_path(@entries.first)
        elsif @entries.count > 1
          # Multiple homographs found - render a selection list
          render :homograph_selection
        else
          redirect_to dic_vocab_index_path, alert: "No detailed entry found."
        end
      end

      def show
        # THE BIG JOIN: Load the entry and all its satellite data
        @entry = Sc03Dictionary::DicEntry.includes(
          dic_index: [:dic_scans, :dic_refs, :dic_notes, :dic_quotes, :dic_egs]
        ).find(params[:id])

        # Data is now accessible via @entry.dic_index.dic_refs, etc.
      end
    end
  end
end