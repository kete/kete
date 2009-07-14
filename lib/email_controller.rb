module EmailController
  unless included_modules.include? EmailController
    # this module DOES NOT cover the following (they must be added per controller)
      # permit declarations (add :contact and :send_email to the :only/:except params as needed)
      # routes (will be accessible via basket/controller/contact by default,
      #         but if you want basket/contact, you need to add that route manually)

    def self.included(klass)
      if klass.name == 'BasketsController'
        settings_method = :prepare_basket_contact_form
      else
        settings_method = :prepare_user_contact_form
      end

      # set a few instance variables to be used later on
      klass.send :before_filter, settings_method, :only => [:contact, :send_email, :redirect_if_contact_form_disabled]

      # make sure we redirect with a flash message
      # if the basket contact form isn't enabled
      klass.send :before_filter, :redirect_if_contact_form_disabled, :only => [:contact, :send_email]
    end

    def contact
      render :template => 'email/contact'
    end

    def send_email
      if params[:contact].nil? || params[:contact][:subject].blank? || params[:contact][:message].blank?
        flash[:error] = I18n.t('email_controller_lib.send_email.need_subject_and_message')
        render :template => 'email/contact'
      else
        # are we sending to multiple recipients, or only one?
        if @recipient.kind_of? Array
          @recipient.each do |recipient|
            UserNotifier.deliver_email_to(recipient, current_user, params[:contact][:subject], params[:contact][:message], @from_basket)
          end
        else
          UserNotifier.deliver_email_to(@recipient, current_user, params[:contact][:subject], params[:contact][:message], @from_basket)
        end
        flash[:notice] = I18n.t('email_controller_lib.send_email.email_sent')
        redirect_to @redirect_to
      end
    end

    private

    def prepare_basket_contact_form
      @contact_form_enabled = @current_basket.allows_contact_with_inheritance?
      @recipient = @current_basket.administrators
      @recipient_name = @current_basket.name
      @from_basket = @current_basket
      @redirect_to = (session[:return_to] || '/')
    end

    def prepare_user_contact_form
      @user = User.find_by_id(params[:id])
      @contact_form_enabled = @user.accepts_emails?
      @recipient = @user
      @recipient_name = @user.user_name
      @from_basket = nil
      @redirect_to = { :controller => 'account', :action => 'show', :id => @user.id }
    end

    def redirect_if_contact_form_disabled
      unless @contact_form_enabled
        flash[:notice] = I18n.t('email_controller_lib.redirect_if_contact_form_disabled.not_enabled')
        redirect_to @redirect_to
      end
    end
  end
end