#= require "../sessions/_login_form_area"

$ ->
  if isOnPage 'frontpage', 'show'
    mconf.Sessions.LoginFormArea.bind()
