$ ->
  if isOnPage 'spaces', 'edit'
    updatePasswords($('input#space_public').is(':checked'))
    $('input#space_public').on 'click', -> updatePasswords($(this).is(':checked'))

    # Dynamic search for institutions
    idInstitution = '#space_institution_name'
    urlInstitutions = '/institutions/select.json'
    $(idInstitution).select2
      minimumInputLength: 0
      multiple: false
      allowClear: true
      placeholder: I18n.t("spaces.edit.institution_placeholder")
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

updatePasswords = (checked) ->
  $('#space_bigbluebutton_room_attributes_attendee_password').prop('disabled', checked)
  $('#space_bigbluebutton_room_attributes_moderator_password').prop('disabled', checked)
