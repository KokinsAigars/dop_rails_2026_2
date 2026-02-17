# frozen_string_literal: true

namespace :db do
  desc "Record the current database release in public.db_release. Usage: bin/rails db:release RELEASE=2026.01.22_01 [NOTES=...] [STATUS=active] [GIT_SHA=...]"
  task release: :environment do
    release_number = ENV["RELEASE"].to_s.strip
    notes          = ENV["NOTES"].to_s.strip.presence
    status         = ENV["STATUS"].to_s.strip.presence || "active"

    if release_number.empty?
      abort "ERROR: RELEASE is required. Example: bin/rails db:release RELEASE=2026.01.22_01"
    end

    git_sha = ENV["GIT_SHA"].to_s.strip.presence
    unless git_sha
      # Convenience for dev; in production prefer ENV["GIT_SHA"]
      git_sha = begin
                  sha = `git rev-parse --short HEAD 2>/dev/null`.to_s.strip
                  sha.presence
                rescue
                  nil
                end
    end

    ActiveRecord::Base.transaction do
      # mark all previous releases as not current
      DbRelease.update_all(is_current: false)

      # upsert-like behavior by number
      rel = DbRelease.find_or_initialize_by(number: release_number)
      rel.status      = status
      rel.released_at = Time.current
      rel.is_current  = true
      rel.git_sha     = git_sha
      rel.notes       = notes
      rel.save!

      puts "DB release recorded:"
      puts "  number:     #{rel.number}"
      puts "  status:     #{rel.status}"
      puts "  is_current: #{rel.is_current}"
      puts "  released_at #{rel.released_at}"
      puts "  git_sha:    #{rel.git_sha || '(none)'}"
      puts "  notes:      #{rel.notes || '(none)'}"
    end
  end
end
