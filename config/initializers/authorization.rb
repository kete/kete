# we have a page per basket that gives information on how to gain access, etc.
DEFAULT_REDIRECTION_HASH = { :controller => 'baskets', :action => 'permission_denied' }

# for flash message when logged in user tries to access something they don't have rights on
PERMISSION_DENIED_MESSAGE = I18n.t('authorization_initializer.permission_denied')
