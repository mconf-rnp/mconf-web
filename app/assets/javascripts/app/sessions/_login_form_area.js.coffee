mconf.Sessions or= {}

class mconf.Sessions.LoginFormArea

  @bind: ->
    area = new mconf.Sessions.LoginFormArea()
    area.bindForm()

  @unbind: ->
    # TODO: can it be done?

  bindForm: ->
    $('.local-sign-in-trigger a').on "click", (e) ->
      $('.local-sign-in-area').fadeToggle(20)
      $('.local-sign-in-area').toggleClass('open')
      $(this).parent().parents('.form-actions').toggleClass('open')
      $(this).parent().toggleClass('open')
      if $('.local-sign-in-area').is(':visible')
        $('.local-sign-in-area input[type=text]:first').focus()
      e.preventDefault()
