class CardController < ApplicationController
  before_action: secret_key
  def new
    card = Card.where(user_id: current_user.id)
    redirect_to action: :show if card.exists?
  end

  def pay
    Payjp.api_key = PAYJP_PRIVATE_KEY
    if params['payjp-token'].blank?
      redirect_to action: :new
    else
      customer = Payjp::Customer.create(
      description: '登録テスト', #なくてもOK
      email: current_user.email, #なくてもOK
      card: params['payjp-token'],
      metadata: {user_id: current_user.id}
      ) #念の為metadataにuser_idを入れましたがなくてもOK
      @card = Card.new(user_id: current_user.id, customer_id: customer.id, card_id: customer.default_card)
      if @card.save
        redirect_to action: "show"
      else
        redirect_to action: "pay"
      end
    end
  end

  def show
    card = Card.where(user_id: current_user.id).first
    binding.pry
    if card.blank?
      redirect_to action: "new"
    else
      Payjp.api_key = PAYJP_PRIVATE_KEY
      customer = Payjp::Customer.retrieve(card.customer_id)
      @default_card_information = customer.cards.retrieve(card.card_id)
    end
  end

  def delete
    card = Card.where(user_id: current_user.id).first
    if card.blank?
    else
      Payjp.api_key = PAYJP_PRIVATE_KEY
      customer = Payjp::Customer.retrieve(card.customer_id)
      customer.delete
      card.delete
    end
    redirect_to action: "new"
  end

  private

  def secret_key
    PAYJP_PRIVATE_KEY = Rails.application.credentials[:payjp][:PAYJP_PRIVATE_KEY]
    PAYJP_KEY = Rails.application.credentials[:payjp][:PAYJP_KEY]
  end

end