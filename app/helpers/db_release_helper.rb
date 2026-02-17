# frozen_string_literal: true

module DbReleaseHelper
  def current_db_release
    @current_db_release ||= DbRelease.find_by(is_current: true)
  end
end
