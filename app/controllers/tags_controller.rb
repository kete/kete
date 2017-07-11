class TagsController < ApplicationController

  def index
    redirect_to action: 'list'
  end

  def list
    @type = @current_basket.index_page_tags_as || 'categories'
    @default_order = @current_basket.index_page_order_tags_by || 'latest'
    @order = params[:order] || @default_order
    @direction = params[:direction] || 'desc'

    @current_page = (params[:page] && params[:page].to_i > 0) ? params[:page].to_i : 1
    # clouds can accommodate more tags per page than category view
    @number_per_page = 75
    @number_per_page = 25 if @type == "categories"

    @tags = @current_basket.tag_counts_array(order: @order,
                                             direction: @direction,
                                             limit: @number_per_page,
                                             page: @current_page,
                                             allow_private: (privacy_type == 'private'))
    @results = WillPaginate::Collection.new(@current_page, @number_per_page, @current_basket.tag_counts_total(allow_private: (privacy_type == 'private')))

    @rss_tag_auto = rss_tag(replace_page_with_rss: true)
    @rss_tag_link = rss_tag(replace_page_with_rss: true, auto_detect: false)

    respond_to do |format|
      format.html
      format.js { render file: File.join(Rails.root, 'app/views/tags/tags_list.js.rjs') }
    end
  end

  def show
    @tag = Tag.find(params[:id])
    @title = t('tags.show.title', tag_name: @tag.name)
  end

  def rss
    @number_per_page = 100
    # this doesn't work with http auth from and IRC client
    @tags = @current_basket.tag_counts_array(order: 'latest',
                                             direction: 'desc',
                                             limit: @number_per_page,
                                             page: @current_page,
                                             allow_private: (privacy_type == 'private'))
    respond_to do |format|
      format.xml
    end
  end

  private

  def privacy_type
    @privacy_type ||= (@current_basket != @site_basket && permitted_to_view_private_items?)
  end

end
