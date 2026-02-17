module HasUiSettings
  extend ActiveSupport::Concern

  def update_ui
    if Current.user.set_ui!(params[:key], params[:value])
      render json: { status: "success", key: params[:key], value: params[:value] }, status: :ok
    else
      render json: { status: "error" }, status: :unprocessable_entity
    end
  end
end