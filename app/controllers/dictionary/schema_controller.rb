# app/controllers/dictionary/schema_controller.rb
module Dictionary
  class SchemaController < ApplicationController
    def index
      respond_to do |format|
        format.html # Normal page load
        format.json do
          render json: {
            explorer_title: "DICTIONARY DATABASE",
            explorer_html: render_to_string(partial: "dictionary/schema/table_list", formats: [:html]),
            edit_html: "<h1>Select a category to explore</h1>"
          }
        end
      end
    end
  end
end