class Cards::WizardsController < ApplicationController
  before_action :check_if_signed_in, only: [:new]

  def new
    @card = current_user.cards.find_by(status: nil)
    if @card.nil?
      @card = current_user.cards.new
      @card.save!(validate: false) # TODO: validate: false may not be necessary later
    end
    redirect_to edit_cards_wizard_path(@card)
  end

  def edit
    # @card = Card.find(params[:id])
  end

  def update
    # @card = Card.find(params[:id])
  end
  
  def confirmation
    # @card = Card.find(params[:id])
  end

  def confirm
    # @card = Card.find(params[:id])
    redirect_to root_path, success: "Vous êtes entré dans le réseau avec succès !"
  end

  private

  def check_if_signed_in
    if current_user.nil?
      redirect_to new_cards_user_path
    end
  end

end
