#= require "../users/new"

$ ->
  if isOnPage 'manage', 'users'
    mconf.Resources.addToBind ->
      mconf.Users.New.bind()

    window.onpopstate = (event) ->
      window.location.href = mconf.Base.urlFromParts(event.state)
      event.state

    $('#institutions_filter').select2
      minimumInputLength: 1
      width: 'resolve'
      multiple: true
      tags: true
      tokenSeparators: [",",";"]

      formatSelection: (object, container) ->
        text = if object.name?
          object.name
        else
          object.text
        mconf.Base.escapeHTML(text)

      ajax:
        url: '/institutions/select'
        dataType: "json"
        data: (term, page) ->
          q: term # search term
        results: (data, page) -> # parse the results into the format expected by Select2.
          results: data

    $('input#institutions_filter').on 'change', ->
      input = $(this)
      baseUrl = $('input.resource-filter').data('load-url')

      params = mconf.Base.getUrlParts(String(window.location))
      if input.val().length > 0
        params.institutions = input.val()
      else
        delete params['institutions']

      console.log params

      history.pushState(params, '', baseUrl + mconf.Base.urlFromParts(params))
      $('input.resource-filter').trigger('update-resources')

    $('input.resource-filter-field').each ->
      input = $(this)
      field = $(this).attr('data-attr-filter')
      baseUrl = $('input.resource-filter').data('load-url')

      $(this).on 'click', ->
        params = mconf.Base.getUrlParts(String(window.location))
        if $(this).is(':checked')
          params[field] = $(this).val()
          opValue = if params[field] is 'true' then 'false' else 'true'
          opElement = $("input[data-attr-filter='#{field}'][value='#{opValue}']")[0]
          opElement.checked = false if opElement?.checked
        else
          delete params[field]

        history.pushState(params, '', baseUrl + mconf.Base.urlFromParts(params))
        $('input.resource-filter').trigger('update-resources')
