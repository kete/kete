class ActionController::Base
  def rescue_action_in_public(exception)
      render :text => <<TOKEN 
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
<html>
<head>
<title>Error!</title>
</head>
<body><h1>Site Error</h1>
<p>A general error has been encountered</p> <p>Error: #{exception} </p></body></html>
TOKEN
   end  
end
