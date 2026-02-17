# frozen_string_literal: true

Kaminari.configure do |config|
  config.default_per_page = 25
  # How many pages to show around the current page (e.g., [1 ... 4 5 (6) 7 8 ... 100])
  config.window = 2

  # How many pages to show at the start and end of the list
  config.outer_window = 1

  # This prevents users from requesting page 999999 if you only have 100 pages
  # config.max_pages = 1000

  # The param name in the URL (?page=2)
  config.param_name = :page

  # config.max_per_page = nil
  # config.left = 0
  # config.right = 0
  # config.page_method_name = :page
  # config.params_on_first_page = false
end
