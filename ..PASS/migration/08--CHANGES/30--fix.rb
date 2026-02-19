# bin/rails generate migration FixAbbrRefIdTypesToUuid
# bin/rails db:migrate

# frozen_string_literal: true

class FixAbbrRefIdTypesToUuid < ActiveRecord::Migration[8.1]
  def up
    # general_terms
    change_column "sc_01_abbreviations.abbr_general_terms", :abbr_ref_id, "uuid USING NULLIF(abbr_ref_id,'')::uuid"

    # grammatical_terms
    change_column "sc_01_abbreviations.abbr_grammatical_terms", :abbr_ref_id, "uuid USING NULLIF(abbr_ref_id,'')::uuid"
  end

  def down
    change_column "sc_01_abbreviations.abbr_general_terms", :abbr_ref_id, :text
    change_column "sc_01_abbreviations.abbr_grammatical_terms", :abbr_ref_id, :text
  end
end
