class Admin::AccessTokensController < Admin::BaseController
	before_action :current_resource, only: [:destroy]
	after_action -> { track_activity(@access_token) }, only: [:create, :destroy]

	def index
		@table = AccessTokenTable.new(self)
		@table.respond
	end

	def create
		@access_token = AccessToken.new(access_token_params)
		@access_token.is_valid = true
		if @access_token.save
			redirect_to admin_access_tokens_path, success: t('access_token.admin.create.success')
		else
			@table = AccessTokenTable.new(self)
			render 'index'
		end
	end

	def destroy
		@access_token.destroy
		redirect_to admin_access_tokens_path, success: t('access_token.admin.destroy.success')
	end

	private

	def access_token_params
		params.require(:access_token).permit(:ownership_id, :exp_at)
	end

	def current_resource
		@access_token = AccessToken.find_by_id(params[:id])
	end

end
