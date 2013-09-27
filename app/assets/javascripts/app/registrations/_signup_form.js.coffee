# http://dense13.com/blog/2009/05/03/converting-string-to-slug-javascript/
stringToSlug = (str) ->
  str = str.replace(/^\s+|\s+$/g, '')
  str = str.toLowerCase()

  # remove accents, swap ñ for n, etc
  from = "ãàáäâẽèéëêĩìíïîõòóöôũùúüûñçć·/_,:;!"
  to   = "aaaaaeeeeeiiiiiooooouuuuuncc-------"
  for i in [0..from.length]
    str = str.replace(new RegExp(from.charAt(i), 'g'), to.charAt(i))

  str.replace(/[^a-z0-9 -]/g, '') # remove invalid chars
     .replace(/\s+/g, '-') # collapse whitespace and replace by -
     .replace(/-+/g, '-') # collapse dashes

class mconf.SignupForm
  @setup: ->
    $fullname = $("#user__full_name")
    $username = $("#user_username")
    $username.attr "value", stringToSlug($fullname.val())
    $fullname.on "input keyup", () ->
      $username.attr "value", stringToSlug($fullname.val())

# Dynamic search for institutions
id = '#user_institution_name'
url = '/institutions/select.json'

$(id).select2
  minimumInputLength: 1
  width: 'resolve'
  multiple: false
  formatSearching: () -> I18n.t('invite_people.users.searching')
  formatInputTooShort: () -> I18n.t('invite_people.users.hint')
  ajax:
    url: url
    dataType: "json"
    data: (term, page) ->
      q: term # search term
    results: (data, page) -> # parse the results into the format expected by Select2.
      results: data

  createSearchChoice: (term, data) ->
    id: term
    text: term
