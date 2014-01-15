class SearchesController < ApplicationController

	def responsables
		if params[:attr].in? %[firstname lastname email]
			render json: Responsable.where("#{params[:attr]} like ?", "#{params[:term]}_%" ).pluck(params[:attr])
		else
			render nothing: true
		end
	end

	def affiliations
		if params[:attr].in? %[name]
			render json: Affiliation.where("#{params[:attr]} like ?", "#{params[:term]}_%" ).pluck(params[:attr])
		else
			render nothing: true
		end
	end

end