class UsersController < ApplicationController
	before_action :connected?, only: [:profile, :edit, :update]

	def new
		@user = User.new
	end

	def create
		@user = User.new(user_params)
		@user.user_type = UserType.find_by_name('user')
		if @user.save
			sign_in(@user)
			redirect_to profile_path, success: t('user.create.success')
		else
			render 'new'
		end
	end

	def edit
		@user = current_user
	end

	def update
		@user = current_user
		if @user.save
			sign_in(@user)
			redirect_to profile_path, success: t('user.edit.success')
		else
			render 'edit'
		end
	end

	# Main page of the user's profile
	def profile
		render layout: 'admin'
	end

	private

	def user_params
		params.require(:user).permit(:name, :email, :password, :password_confirmation)
	end

	def connected?
		redirect_to root_path, error: "Please sign in" if current_user.nil?
	end
end
