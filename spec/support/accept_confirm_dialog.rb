# frozen_string_literal: true

def accept_confirm_dialog
  # page.driver.browser.switch_to.alert.accept is a selenium only feature
  # (poltergeist does not have it). Instead poltergiest always returns true from
  # modal dialogs so it will accept by default
  page.driver.browser.switch_to.alert.accept unless Capybara.javascript_driver == :poltergeist
end
