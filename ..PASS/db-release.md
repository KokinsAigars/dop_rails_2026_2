

add db release, lib/tasks/db_release.rake

    bin/rails db:release RELEASE=2026.01.27_01 NOTES="Adding users. Ready for api point"

# in Production
    
    GIT_SHA=$(git rev-parse --short HEAD) \
    bin/rails db:release RELEASE=2026.01.23_01 NOTES="deploy #17"
    
# Verify

    bin/rails runner "p DbRelease.where(is_current: true).pluck(:number, :git_sha, :released_at)"





