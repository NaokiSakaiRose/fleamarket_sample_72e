class ItemsController < ApplicationController
  before_action -> {
    set_payjp_api
    set_user
    set_item
  },only: [:confirm,:purchase]

  before_action :move_to_index

  def new
    @item = Item.new
    @item.itemimages.build
  end

  def create
    @item = Item.new(item_params)
    if @item.save
      redirect_to root_path
      # フラッシュメッセージを利用する場合は、以下に置き換え
      # redirect_to root_path, notice: '商品を出品しました'
    else
      render :new
      @item = Item.new(item_params)
      @item.itemimages.build
    end
  end

  def confirm

    # ログイン機能実装後以下を使用
    # unless user_signed_in? redirect_to login_path
    # if current_user.creditcards.present? then
    # @customer = Payjp::Customer.retrieve(current_user.credicards.first)
    if @user.creditcards.present? then
      @customer = Payjp::Customer.retrieve(@user.creditcards.first.payjp_custumer_id)
      @cards = @customer.cards
    else
      redirect_to new_creditcard_path  
    end

    if @item.closed_time.present? then 
      redirect_to root_path
    end
  end

  def purchase
    # current_user使用できるようになったら以下に切り替え
    # unless user_signed_in? redirect_to login_path
    if @item.closed_time.present? then
      redirect_to root_path
      return
    end
    
    begin
      @charge = Payjp::Charge.create(
        amount: @item.price,
        customer: params[:payjp_customer_id],
        card: params[:payjp_card_id],
        currency: 'jpy',
      )
      @item.closed_time = Time.now
      @item.buyer_id = @user.id
      @item.save
      redirect_to root_path
    rescue => error
      p error
      redirect_to confirm_item_path
    end
  end

  private
  def set_item
    begin
      @item = Item.find(params[:id])
    rescue
      redirect_to root_path
    end
  end

  def set_user
    # current_user使用できるようになったら以下に切り替え
    # @user = current_user.id
    @user = User.find(1)
  end

  def set_payjp_api
    Payjp.api_key = Rails.application.credentials[:PAYJP_SECRET_KEY]
  end
  
  def item_params
    params.require(:item).permit(:name, :description, :category_id, :size, :brand_id, :condition_id, :postage_id, :prefecture_id, :preparation_id, :price, itemimages_attributes: [:image]).merge(user_id: current_user.id, status: 1)
  end

  def move_to_index
    redirect_to root_path unless user_signed_in?
  end

end
