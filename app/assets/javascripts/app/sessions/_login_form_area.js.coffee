mconf.Sessions or= {}

class mconf.Sessions.LoginFormArea

  @bind: ->
    area = new mconf.Sessions.LoginFormArea()
    area.bindForm()

  @unbind: ->
    # TODO: can it be done?

  bindForm: ->
    $('.local-sign-in-trigger a').on "click", (e) ->
      $('.box-shibboleth').removeClass("open")
      $('.box-local').addClass("open")
      $('.box-local input').filter(":visible:first").focus()
      e.preventDefault()

    $('.shib-sign-in-trigger a').on "click", (e) ->
      $('.box-local').removeClass("open")
      $('.box-shibboleth').addClass("open")
      e.preventDefault()
