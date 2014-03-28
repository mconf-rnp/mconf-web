class mconf.SignupForm
  @setup: ->
    $fullname = $("#user__full_name")
    $username = $("#user_username")
    $username.attr "value", mconf.Base.stringToSlug($fullname.val())
    $fullname.on "input keyup", () ->
      $username.attr "value", mconf.Base.stringToSlug($fullname.val())

    # Dynamic search for institutions
    idInstitution = '#user_institution_id'
    urlInstitutions = '/institutions/select.json'
    $(idInstitution).select2
      minimumInputLength: 0
      placeholder: I18n.t('users.registrations.signup_form.institution_hint')
      width: 'resolve'
      multiple: false
      initSelection: (element, callback) ->
        params = { dataType: "json" }
        $.ajax("#{urlInstitutions}?q=#{element.val()}", params).done (data) ->
          callback(data?[0])
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
