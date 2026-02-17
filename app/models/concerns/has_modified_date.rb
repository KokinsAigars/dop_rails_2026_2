# frozen_string_literal: true

# Adds automatic maintenance of a `modified_date` timestamp to a model.
#
# When included, a `before_update` callback writes the current time
# to the record's `modified_date` column on every successful update.
#
# Requirements:
# - The including model MUST define a `modified_date` attribute (e.g., a
#   `:datetime`/`:timestamp` column).
#
# @example Enable modified-date tracking on a model
#   class Document < ApplicationRecord
#     include HasModifiedDate
#   end
#
# @see ActiveSupport::Callbacks before_update
module HasModifiedDate
  extend ActiveSupport::Concern

  included do
    # Touch the `modified_date` field right before persisting an update.
    #
    # @!scope class
    # @!visibility public
    before_update :touch_modified_date
  end

  private

  # Sets `modified_date` to the current time.
  #
  # @return [void]
  # @!visibility private
  def touch_modified_date
    self.modified_date = Time.current
  end
end
