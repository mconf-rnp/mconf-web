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
    idInstitution = '#user_institution_name'
    urlInstitutions = '/institutions/select.json'
    $(idInstitution).select2
      minimumInputLength: 0
      placeholder: I18n.t('users.registrations.signup_form.institution_hint')
      width: 'resolve'
      multiple: false
      ajax:
        url: urlInstitutions
        dataType: "json"
        data: (term, page) ->
          q: term # search term
        results: (data, page) -> # parse the results into the format expected by Select2.
          results: data

# Uncommenting this makes it possible to add a new institution by suggesting a new name
#  createSearchChoice: (term, data) ->
#    id: term
#    text: term
