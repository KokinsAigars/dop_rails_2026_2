# frozen_string_literal: true

module Admin
  module Management
    class GlobalConfigsController < Admin::BaseController
      skip_before_action :load_explorer_users, raise: false

      def index
        # @configs = GlobalConfig.all.order(:key)
        @configs = GlobalConfig.all
      end

      def update
        @config = GlobalConfig.find(params[:id])
        # Toggle logic: if it's "true", make it "false" and vice-versa
        new_value = @config.value == "true" ? "false" : "true"

        if @config.update(value: new_value)
          # Optional: Clear cache if you implemented the caching tip earlier
          # Rails.cache.delete("global_config/#{@config.key}")

          redirect_to admin_global_configs_path, notice: "#{@config.key.humanize} updated."
        end
      end
    end
  end
end
