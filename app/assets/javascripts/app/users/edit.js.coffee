# Dynamic search for institutions
idInstitution = '#user_institution_name'
urlInstitutions = '/institutions/select.json'
$(idInstitution).select2
  minimumInputLength: 0
  placeholder: I18n.t('user.hint.institution')
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