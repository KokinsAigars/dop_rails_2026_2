# frozen_string_literal: true

#  using: GitInfo.sha

module GitInfo
  def self.sha
    return ENV["GIT_SHA"] if ENV["GIT_SHA"].present?

    sha = `git rev-parse --short HEAD`.strip
    sha.presence
  rescue
    nil
  end
end
