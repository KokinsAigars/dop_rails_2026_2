# frozen_string_literal: true

# Base class for all ActiveRecord models in the application.
# Provides a central point for shared logic and configuration.
#
# @abstract
class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class
end
