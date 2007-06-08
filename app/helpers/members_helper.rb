module MembersHelper

  def site_admin_actions_correct_list_item(user, action_key, action_label, tool_count)
    html_string = String.new
    case action_key
    when 'destroy'
      user_contributions = user.contributions.size
      if user_contributions == 0
        html_string = li_with_correct_class(tool_count) + link_to( action_label, { :action => :destroy, :id => user }, :confirm => 'Are you sure?', :method => :post ) + '</li>'
      else
        html_string = li_with_correct_class(tool_count) + user_contributions.to_s + ' contributions</li>'
      end
    when 'ban'
      if !user.banned_at.nil?
        html_string = li_with_correct_class(tool_count) + 'Banned ' + user.banned_at.to_s(:euro_date_time) + link_to( '(undo)', { :action => 'unban', :id => user }, :confirm => 'Are you sure?', :method => :post ) + '</li>'
      else
        html_string = li_with_correct_class(tool_count) + link_to( action_label, { :action => action_key, :id => user }, :confirm => 'Are you sure?', :method => :post ) + '</li>'
      end
    else
      html_string = li_with_correct_class(tool_count) + link_to( action_label, { :action => action_key, :id => user }, :confirm => 'Are you sure?', :method => :post ) + '</li>'
    end
  end
end
