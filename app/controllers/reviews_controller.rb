class ReviewsController < ApplicationController
  def index
    @reviews = Review.active.ordered
  end

  def show
    @review = Review.friendly.find(params[:slug])
  end
end
