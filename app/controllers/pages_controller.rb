class PagesController < ApplicationController

	def home
		@page = Page.find_by_name('home')
	end
	
end