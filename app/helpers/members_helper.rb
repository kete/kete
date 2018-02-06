# frozen_string_literal: true

module MembersHelper
  def admin_actions_correct_list_item(user, action_key, action_label, tool_count)
    html_string = String.new

    case action_key
    when 'destroy'
      user_contributions = user.contributions.size

      if user_contributions == 0
        html_string = li_with_correct_class(tool_count) +
                      link_to(
                        action_label,
                        { action: :destroy, id: user, authenticity_token: form_authenticity_token },
                        confirm: t('members_helper.admin_actions_correct_list_item.are_you_sure'),
                        method: :post
                      )
      else
        html_string = li_with_correct_class(tool_count) +
                      user_contributions.to_s +
                      ' contributions'
      end
    when 'ban'
      if !user.banned_at.nil?
        html_string = li_with_correct_class(tool_count) +
                      t('members_helper.admin_actions_correct_list_item.banned') +
                      user.banned_at.to_s(:euro_date_time) +
                      link_to(
                        t('members_helper.admin_actions_correct_list_item.undo'),
                        { action: 'unban', id: user, authenticity_token: form_authenticity_token },
                        confirm: t('members_helper.admin_actions_correct_list_item.are_you_sure'),
                        method: :post
                      )
      else
        html_string = li_with_correct_class(tool_count) +
                      link_to(
                        action_label, { 
                          action: action_key,
                          id: user,
                          authenticity_token: form_authenticity_token 
                        },
                        confirm: t('members_helper.admin_actions_correct_list_item.are_you_sure'),
                        method: :post
                      )
      end
    else
      html_string = li_with_correct_class(tool_count) +
                    link_to(
                      action_label,
                      { action: action_key, id: user, authenticity_token: form_authenticity_token },
                      confirm: t('members_helper.admin_actions_correct_list_item.are_you_sure'),
                      method: :post
                    )
    end
  end
end
