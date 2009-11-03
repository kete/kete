# based on acts_as_commentable, but customized to suit kete
module KeteCommentable
  unless included_modules.include? KeteCommentable
    def self.included(klass)
      # we can't use object.comments, because that is used by related content stuff
      klass.send :has_many, :comments, :as => :commentable, :dependent => :destroy, :order => 'lft'

      klass.class_eval do

        # if the model we're mixing into has public/private, then only return comments
        # that have suitable privacy
        def non_pending_comments
          if respond_to?(:private?)
            comments.all(:conditions => ['title != ? AND commentable_private = ?', BLANK_TITLE, private?])
          else
            comments.all(:conditions => ['title != ?', BLANK_TITLE])
          end
        end

      end
    end


  end
end
