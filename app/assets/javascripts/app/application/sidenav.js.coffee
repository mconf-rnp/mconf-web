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

    # button that opens the sidenav
    $(document).on "click.mconfSidenav", ".sidenav-trigger", (e) ->
      open()
      e.preventDefault()

    # clicking on the back closes the sidenav
    $(document).on "click.mconfSidenav", ".sidenav-backdrop", (e) ->
      close()
      e.preventDefault()

    # pressing ESC closes the sidenav
    $(document).on "keyup", (e) ->
      close() if e.keyCode is 27
      e.preventDefault()

    # the close button closes the sidenav
    $(document).on "click.mconfSidenav", ".sidenav .close", (e) ->
      close()
      e.preventDefault()

    # clicking in an item in the sidenav closes it before triggering the action
    $(document).on "click.mconfSidenav", "a.sidenav-item", (e) ->
      close()

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
