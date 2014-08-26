$ ->
  if isOnPage 'spaces', 'edit'
    updatePasswords($('input#space_public').is(':checked'))
    $('input#space_public').on 'click', -> updatePasswords($(this).is(':checked'))

    uploaderCallbacks =
      onComplete: (id, name, response) ->
        if response.success
          $.get response.redirect_url, (data) ->
            # show the crop modal
            mconf.Modal.showWindow
              data: data

    mconf.Uploader.bind
      callbacks: uploaderCallbacks

    # Dynamic search for institutions
    idInstitution = '#space_institution_id'
    urlInstitutions = '/institutions/select.json'
    $(idInstitution).select2
      minimumInputLength: 0
      multiple: false
      allowClear: true
      width: '100%'
      placeholder: I18n.t("spaces.edit.institution_placeholder")
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

updatePasswords = (checked) ->
  $('#space_bigbluebutton_room_attributes_attendee_key').prop('disabled', checked)
  $('#space_bigbluebutton_room_attributes_moderator_key').prop('disabled', checked)
