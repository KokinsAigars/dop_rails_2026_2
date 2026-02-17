# frozen_string_literal: true

source "https://rubygems.org" # gems are fetched from

ruby "3.4.7"
gem "rails", "~> 8.1.1"
gem "bundler", "~> 4.0", ">= 4.0.4"

gem "puma", ">= 5.0"                    # HTTP application server for Ruby.

gem "pg", "~> 1.6", ">= 1.6.2"          # ActiveRecord uses it to talk to Postgres

gem "doorkeeper"                        # Authentification for API calls
gem "bcrypt", "~> 3.1", ">= 3.1.21"     # password hashing; devise already depends on it

gem "kamal", "~> 2.9"                   # for deploying app

# VITE build Tool for JavaScript and CSS.
gem "vite_rails", "~> 3.0", ">= 3.0.17" # Compile, bundle, optimize JS/CSS; handles TypeScript
gem "vite_ruby", "~> 3.9", ">= 3.9.2"

# STIMULUS CONTROLLER - define how Rails uses that JavaScript
gem "stimulus-rails", "~> 1.3", ">= 1.3.4" # Stimulus controller integration

# TURBO RAILS - define how Rails uses that JavaScript
gem "turbo-rails", "~> 2.0", ">= 2.0.17" # Turbo Drive/Frames/Streams integration

# PROPSHAFT - delivers the final assets
gem "propshaft", "~> 1.3", ">= 1.3.1"   # Deliver static assets via Rails, fingerprints assets

# internationalization
gem "i18n", "~> 1.14", ">= 1.14.7"      # the core internationalization engine
gem "i18n-js", "~> 4.2", ">= 4.2.4"     # expose translations to JavaScript
gem "rails-i18n", "~> 8.1"              # locale data for Rails
gem "route_translator", "~> 15.2"       # automatically translated routes per locale


gem "resend", "~> 1.0" # e-mails form rails

# To help IntelliJ see these methods, you need to generate YARD sticks (documentation) that the IDE can read.
gem "solargraph", "~> 0.58.2"

gem "meta-tags", "~> 2.22", ">= 2.22.3" # HTML meta tags management


gem "bootsnap", require: false # Reduces boot times through caching; required in config/boot.rb

# Processing images
gem "image_processing", "~> 1.2"          # high-level image pipeline (resize, crop, convert, strip metadata)
gem "ruby-vips", "~> 2.3", require: false # libvips image processing backend. install libvips at OS level (Dockerfile)

gem "activestorage", "~> 8.1", ">= 8.1.1" # file uploads and attachments, config/storage.yml
gem 'aws-sdk-s3', '~> 1.213'              # MinIO file server


# JSON
gem "jbuilder", "~> 2.14", ">= 2.14.1"    # JSON view templates
gem "oj", "~> 3.16", ">= 3.16.12"         # a high-performance JSON parser/encoder. config/initializers/oj.rb
gem "oj_mimic_json", "~> 1.0", ">= 1.0.1" # makes Oj act like the standard JSON module


# PAGE BEAUTY
gem 'kaminari', '~> 1.2', '>= 1.2.2'


group :development, :test do
  gem "debug", platforms: %i[ mri windows ], require: "debug/prelude" # debugger (breakpoints, stepping, etc.).
  gem "faker" # fake data for development/test
end

group :development do
  # gem "letter_opener" # testing e-mail sent

  # can be run: bundle exec rubocop
  gem "rubocop-rails-omakase", require: false # opinionated code style. Style choices aligned with “Rails Way”

  # to run: bundle exec bundler-audit check --update
  gem "bundler-audit", require: false # Audits gems for known security defects (use config/bundler-audit.yml to ignore issues)

  # to run: bundle exec brakeman
  gem "brakeman", require: false  # Static analysis for security vulnerabilities

  # run it: bundle exec database_consistency
  gem "database_consistency", "~> 2.0", ">= 2.0.8", require: false # checks consistency between Rails models and the DB schema

  gem "web-console"   # interactive Ruby console in the browser on error pages
  gem "listen", "~> 3.9"  # file system watcher so Rails reloads code automatically when files change.
  gem "annotate"  # adds schema comments at the top of models

  # gem "sshkit-sudo" # ssh for kamal deploy ? if not - remove
  gem "ed25519", ">= 1.2", "< 2.0"  # for ssh keys
  gem "bcrypt_pbkdf", ">= 1.0", "< 2.0"  # for ssh keys

  gem "pry", "~> 0.15.2"  # interactive Ruby REPL
  gem "rb-readline", "~> 0.5.5" # readline for Pry on some systems
end

group :test do
  gem "rspec-rails", "~> 8.0", ">= 8.0.2" # RSpec integration with Rails
  gem "factory_bot", "~> 6.5", ">= 6.5.6" # test data factories
  gem "rspec-json_expectations", "~> 2.2" # JSON matchers helper
  gem "capybara"  # system/feature testing (simulates a real user clicking around your app)
  gem "selenium-webdriver"  # Drives a real browser (Chrome/Firefox) for Capybara.
  gem "webdrivers"  # Automated downloads and manages browser drivers
  gem "launchy", "~> 3.1", ">= 3.1.1" # Opens pages in a browser during tests
  gem "shoulda-matchers", "~> 7.0", ">= 7.0.1"  # one-liner for model tests
  gem "db-query-matchers", "~> 0.15.0"  # Helps assert the number / pattern of DB queries
end


# Windows does not include zoneinfo files (timezone database), so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: %i[ windows jruby ]

gem 'fiddle', '~> 1.1', '>= 1.1.8'  # A libffi wrapper for Ruby.
gem 'psych', '~> 5.3', '>= 5.3.1'   # Psych is a YAML parser and emitter.