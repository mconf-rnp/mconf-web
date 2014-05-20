$ ->
  if isOnPage 'users', 'edit'

    $("#user_timezone").select2
      minimumInputLength: 0
      width: '100%'

    # Dynamic search for institutions
    idInstitution = '#user_institution_id'
    urlInstitutions = '/institutions/select.json'
    $(idInstitution).select2
      minimumInputLength: 0
      multiple: false
      allowClear: true
      placeholder: I18n.t("users.edit.institution_placeholder")
      width: "50%"
      initSelection: (element, callback) ->
        data = { id: element.val(), text: element.data("institution-name") }
        callback(data)
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
