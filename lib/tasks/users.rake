# frozen_string_literal: true

# bin/rails users:cleanup_unverified

namespace :users do
  desc "Remove unverified users who haven't confirmed their email within 3 days"
  task cleanup_unverified: :environment do
    count = User.where(verified_at: nil)
                .where("created_at < ?", 3.days.ago)
                .destroy_all
                .count

    puts "Done! Swept away #{count} dead accounts."
  end
end
