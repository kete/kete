# based on acts_as_commentable, but customized to suit kete
module KeteCommentable
  unless included_modules.include? KeteCommentable
    def self.included(klass)
      # we can't use object.comments, because that is used by related content stuff
      klass.send :has_many, :comments, :as => :commentable, :dependent => :destroy, :order => 'position'
    end
  end
end
