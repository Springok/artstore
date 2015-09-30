class OrdersController < ApplicationController
  before_action :authenticate_user!, except: :allpay_notify
  protect_from_forgery except: :allpay_notify

  def create
    @order = current_user.orders.build(order_params)

    if @order.save
      @order.build_item_cache_from_cart(current_cart)
      @order.calculate_total!(current_cart)
      current_cart.cart_items.destroy_all
      redirect_to order_path(@order.token)
    else
      render "carts/checkout"
    end

  end

  def show
    @order = Order.find_by_token(params[:id])
    @order_info = @order.info
    @order_items = @order.items

  end

  def pay_with_credit_card
    @order = Order.find_by_token(params[:id])
    @order.set_payment_with!("credit_card")
    @order.make_payment!

    redirect_to account_orders_path, notice: "成功完成付款"
  end


  def allpay_notify
    order = Order.find_by_token(params[:id])
    type = params[:type]

    if params[:RtnCode] == "1"
      order.set_payment_with!(type)
      order.make_payment!
    end

    render text: '1|OK', status: 200
  end


  private

  def order_params
    params.require(:order).permit(info_attributes: [:billing_name, :billing_address, :shipping_name, :shipping_address])
  end

end
