class Admin::CardStatusesController < Admin::BaseController
	before_action :current_resource, only: [:edit, :update]
	after_action only: [:update] { |c| c. track_activity @card }

	def index
		@table = CardTable.new(self, nil, buttons: false, search: true)
		@table.respond
	end

	def edit
	end

	def update
		status = Status.find(params[:card][:status_id])
		old_status = @card.status
		@card.status = status
		# don't do anything if not changed
		if !@card.changed?
			@card.errors.add(:status, "Le status n'a pas changé")
			render 'edit'
		else # if status is changed
			if @card.save
				CardMailer.changed_status(@card, status, old_status, params[:message]).deliver_later
				redirect_to admin_card_statuses_path, success: t('card_status.admin.edit.success')
			else
				render 'edit'
			end
		end
	end

	private

	def current_resource
		@card = Card.find_by_id(params[:id])
	end
end
