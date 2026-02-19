# bin/rails generate migration StopBeforePgRestore
# bin/rails db:migrate

# frozen_string_literal: true

class StopBeforePgRestore < ActiveRecord::Migration[8.1]
  def change
    # INTENTIONAL NO-OP
    # Marker migration:
    # Run pg_restore --data-only AFTER this point
    # then continue migration
  end
end
