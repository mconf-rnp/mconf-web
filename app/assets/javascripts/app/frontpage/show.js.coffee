#= require "../registrations/_signup_form"

$ ->
  if isOnPage 'frontpage', 'show'

    # workaround to remove focus from the login input when in the frontpage,
    # since the focus should be on the federated sign in
    # only for the frontpage, in the sign in page the focus is good
    $(':focus').blur()
