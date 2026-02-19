# app/controllers/dictionary/dic/entries_controller.rb
module Dictionary
  module Dic
    class EntriesController < ApplicationController

      # This is the action that was "missing"
      def index

        query = params[:q]

        # Try 1: Direct match (finds the exact messy string)
        @entries = Sc03Dictionary::DicEntry
                     .where(lang: params[:lang], is_current: true)
                     .where("name = :q OR name ILIKE :fuzzy", q: query, fuzzy: "%-#{query}")

        # Try 2: If nothing found, try searching by "dic_name" or "name_orig"
        # which might be cleaner versions of the word
        if @entries.empty?
          clean_name = query.gsub(/[1234567890\[\]\-\/]/, '')
          @entries = Sc03Dictionary::DicEntry.where("name ILIKE ?", "#{clean_name}%")
                                             .where(lang: params[:lang], is_current: true)
        end

        if @entries.count == 1
          # If exactly one exists, skip the list and go to the full data
          redirect_to dic_entry_path(@entries.first)
        elsif @entries.count > 1
          # If multiple (homographs), show a selection page
          render :homograph_selection
        else
          # If none, go back to search with a warning
          redirect_to dic_vocab_index_path(lang: params[:lang]), alert: "Entry details not found."
        end
      end

      def show

        # params[:id] is the word from the URL, e.g., "a-baddha"
        word_from_url = params[:id]

        # We "search again" inside the show action to find the current version
        @entry = Sc03Dictionary::DicEntry.find_by(
          name: word_from_url,
          is_current: true,
          lang: params[:lang] || 'pi' # Default to Pali if lang isn't specified
        )

        if @entry
          @index_head = @entry.dic_index
          @scans = @index_head.dic_scans.where(is_current: true)
          @related_entries = @index_head.dic_entries.where(is_current: true)
        else
          # Fallback if no "current" version exists
          render "not_found"
        end

        #
        # # SELECT * FROM dic_entry WHERE id = 123;
        # @entry = Sc03Dictionary::DicEntry.includes(:dic_index).find(params[:id])
        #
        # # SELECT * FROM dic_index WHERE id = [fk_index_id_value];
        # @index_head = @entry.dic_index
        #
        # # SELECT * FROM dic_scan WHERE fk_index_id = [@index_head.id];
        # @scans = @index_head.dic_scans.where(is_current: true)
        #
        #
        # @related_entries = @index_head.dic_entries.where(is_current: true)
      end

      # def show
      #   # 1. Load the entry and eager-load ITS children (refs, notes, quotes, egs)
      #   # 2. Also eager-load the parent index and the index's children (scans)
      #   @entry = Sc03Dictionary::DicEntry.includes(
      #     :dic_refs, :dic_notes, :dic_quotes, :dic_egs,
      #     dic_index: [:dic_scans]
      #   ).find(params[:id])
      #
      #   # 3. Correctly map the variables for the view
      #   @index  = @entry.dic_index
      #
      #   # These come from the Entry
      #   @refs   = @entry.dic_refs.where(is_current: true).order(:ref_no)
      #   @egs    = @entry.dic_egs.where(is_current: true).order(:eg_no)
      #   @quotes = @entry.dic_quotes.where(is_current: true).order(:quote_no)
      #   @notes  = @entry.dic_notes.where(is_current: true).order(:note_no)
      #
      #   # These come from the Index
      #   @scans  = @index.dic_scans.where(is_current: true)
      # end
    end
  end
end