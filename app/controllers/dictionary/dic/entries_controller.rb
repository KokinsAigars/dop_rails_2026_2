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

        # 1. params[:id] is now the UUID (fk_index_id) from the link
        @index_head = Sc03Dictionary::DicIndex.find_by(id: params[:id])

        # Safety check: if no index found, go back to search
        if @index_head.nil?
          return redirect_to dic_root_path, alert: "Index record not found."
        end

        # 2. Get all language versions (Pali, Latvian, etc.) linked to this UUID
        # We explicitly filter by is_current to ensure we see the latest versions
        @entries = Sc03Dictionary::DicEntry.where(
          fk_index_id: @index_head.id,
          is_current: true
        ).order(:lang)

        # Use the first entry's name as the main title for the page
        @page_title = @entries.any? ? @entries.first.name : "Word Not Found"

        # 3. Get all manuscript scans tied to this UUID
        @scans = Sc03Dictionary::DicScan.where(
          fk_index_id: @index_head.id,
          is_current: true
        )
      end

    end
  end
end