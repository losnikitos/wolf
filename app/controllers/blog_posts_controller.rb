class BlogPostsController < ApplicationController
  def index
    posts = BlogPost.active.ordered
    @posts_by_year = posts.group_by { |post| post.published_year || "Unknown" }
    @year_names = @posts_by_year.keys.sort_by { |year| year == "Unknown" ? 0 : year.to_i }.reverse
  end

  def show
    @post = BlogPost.friendly.find(params[:slug])
  end
end
