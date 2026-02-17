# frozen_string_literal: true

module Admin
  module Management
    class StorageController < Admin::BaseController

      def explorer
        @path = params[:path] || ""
        @contents = MinioExplorerService.new("my-bucket", @path).list_contents

        render partial: "admin/storage/explorer_list", layout: false
      end

      def breadcrumbs(path)
        parts = path.split('/').reject(&:empty?)
        nodes = []
        current_path = ""

        parts.each do |part|
          current_path += "#{part}/"
          nodes << { name: part, path: current_path }
        end
        nodes
      end


    end
  end
end


