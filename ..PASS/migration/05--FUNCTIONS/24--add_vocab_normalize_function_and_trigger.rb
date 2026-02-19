# bin/rails generate migration AddVocabNormalizeFunctionAndTrigger
# bin/rails db:migrate

# frozen_string_literal: true

class AddVocabNormalizeFunctionAndTrigger < ActiveRecord::Migration[8.1]
  def up
    enable_extension "unaccent" unless extension_enabled?("unaccent")

    execute <<~SQL
      CREATE OR REPLACE FUNCTION public.fn_vocab_normalize()
      RETURNS trigger
      LANGUAGE plpgsql
      AS $$
      BEGIN
        NEW.term_norm := lower(unaccent(trim(NEW.term)));
        RETURN NEW;
      END;
      $$;
    SQL

    execute <<~SQL
      DROP TRIGGER IF EXISTS trg_vocab_normalize ON sc_03_dictionary.dic_vocab;
      CREATE TRIGGER trg_vocab_normalize
      BEFORE INSERT OR UPDATE OF term
      ON sc_03_dictionary.dic_vocab
      FOR EACH ROW
      EXECUTE FUNCTION public.fn_vocab_normalize();
    SQL

    execute <<~SQL
      UPDATE sc_03_dictionary.dic_vocab
      SET term_norm = lower(unaccent(trim(term)))
      WHERE term IS NOT NULL;
    SQL
  end

  def down
    execute "DROP TRIGGER IF EXISTS trg_vocab_normalize ON sc_03_dictionary.dic_vocab;"
    execute "DROP FUNCTION IF EXISTS public.fn_vocab_normalize();"
  end
end
