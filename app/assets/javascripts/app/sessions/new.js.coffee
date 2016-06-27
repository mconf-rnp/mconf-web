#= require "../sessions/_login_form_area"

$ ->
  if isOnPage('sessions', 'new') || isOnPage('sessions', 'create')
    mconf.Sessions.LoginFormArea.bind()
