container = "#webconf-room-invite-header .room-status"

$ ->
  if isOnPage 'custom_bigbluebutton_rooms', 'invite|invite_userid|auth'
    bindLocalSignIn()
    updateStatus()
    setInterval updateStatus, 10000

bindLocalSignIn = ->
  $('.local-sign-in-trigger a').on "click", (e) ->
    $('.local-sign-in-area').slideToggle()
    $('.local-sign-in-area').toggleClass('open')
    $(this).parent().toggleClass('open')
    if $('.local-sign-in-area').is(':visible')
      $('.local-sign-in-area input[type=text]:first').focus()
    e.preventDefault()

updateStatus = ->
  url = $(container).attr("data-url")
  $.ajax
    url: url
    dataType: "json"
    error: errorStatus
    success: successStatus
    contentType: "application/json"

errorStatus = (data) ->
  $(".status", container).text("?")

successStatus = (data) ->
  target = $(".status", container)
  if data.running is "false"
    target.removeClass("label-success")
    target.addClass("label-important")
    target.text(I18n.t('custom_bigbluebutton_rooms.invite_header.not_running'))
  else
    target.removeClass("label-important")
    target.addClass("label-success")
    target.text(I18n.t('custom_bigbluebutton_rooms.invite_header.running'))
