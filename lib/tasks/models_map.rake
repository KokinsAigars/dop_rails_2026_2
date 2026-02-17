# bin/rails dev:models_map

# frozen_string_literal: true

namespace :dev do
  desc "Print ActiveRecord associations per model"
  task models_map: :environment do
    models = ApplicationRecord.descendants.sort_by(&:name)

    models.each do |m|
      next if m.abstract_class?
      next unless m.respond_to?(:reflections)

      puts "\n== #{m.name} (#{m.table_name})"
      m.reflections.each do |name, refl|
        puts "  #{refl.macro} :#{name} -> #{refl.class_name} (fk: #{refl.foreign_key})"
      end
    end
  end
end
