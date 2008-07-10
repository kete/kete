class Document < ActiveRecord::Base
  belongs_to :author
  acts_as_licensed
	
  def title_for_license
    title
  end

  def author_for_license
    self.author.name
  end
  
  def author_url_for_license
    "/site/account/show/#{author_id}"
  end
		
end

