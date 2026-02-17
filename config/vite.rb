# frozen_string_literal: true

ViteRuby.configure do |config|
  config.dev_server = {
    host: "127.0.0.1",  # same container
    port: 3040,
    https: false
  }
end
