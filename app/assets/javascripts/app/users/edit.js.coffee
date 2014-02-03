$ ->
  if isOnPage 'users', 'edit'
    # Dynamic search for institutions
    idInstitution = '#user_institution_name'
    urlInstitutions = '/institutions/select.json'
    $(idInstitution).select2
      minimumInputLength: 0
      multiple: false
      allowClear: true
      placeholder: I18n.t("users.edit.institution_placeholder")
      initSelection: (element, callback) ->
        data = { id: element.val(), text: element.val() }
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
