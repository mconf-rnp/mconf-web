# Navigation sidebar similar to menus in mobile devices
class mconf.Sidenav

  # Clicking in the checkboxes changes the type of the input to text/password.
  @bind: ->
    @unbind()

    open = ->
      $(".sidenav").addClass("open")
      $backdrop = $('<div></div>')
      $backdrop.addClass('sidenav-backdrop')
      $("body").append($backdrop)

      # for the transition effect
      setTimeout( ->
        $('.sidenav-backdrop').addClass('open')
      , 10)

    close = ->
      $(".sidenav").removeClass("open")
      $('.sidenav-backdrop').remove()

    $(document).on "click.mconfSidenav", ".sidenav-trigger", ->
      open()
      false
    $(document).on "click.mconfSidenav", ".sidenav-backdrop", ->
      close()
    $(document).on "click.mconfSidenav", ".sidenav .close", ->
      close()
    $(document).on "keyup", (e) ->
      close() if e.keyCode is 27

    hoverIn = ->
      $(this).prev().addClass("hover-sibling")
    hoverOut = ->
      $(this).prev().removeClass("hover-sibling")
    $(".sidenav-item").hover hoverIn, hoverOut

  @unbind: ->
    $(document).off "click.mconfSidenav", ".sidenav-trigger"
    $(document).off "click.mconfSidenav", ".sidenav-backdrop"
    $(document).off "click.mconfSidenav", ".sidenav .close"

$ ->
  mconf.Sidenav.bind()
  mconf.Resources.addToBind ->
    mconf.Sidenav.bind()
