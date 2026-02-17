# frozen_string_literal: true

module Admin::NavigationHelper
  def admin_nav_link(label, path, allowed:)
    return unless allowed
    link_to label, path, class: "admin-link"
  end
end
