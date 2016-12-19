#= require "../users/new"

$ ->
  if isOnPage 'manage', 'users'
    mconf.Resources.addToBind ->
      mconf.Users.New.bind()

    window.onpopstate = (event) ->
      window.location.href = mconf.Base.makeQueryString(event.state) if event.state
      event.state

    $('#institutions').select2
      minimumInputLength: 1
      width: '715'
      multiple: true
      tags: true
      tokenSeparators: [",",";"]

      formatSelection: (object, container) ->
        mconf.Base.escapeHTML(object.text)

      initSelection: (element, callback) ->
        data = []
        ids = element.val()?.split(',')

        return unless ids?

        fetch_data_and_callback = (index) ->
          if index >= ids.length
            callback(data)
          else
            $.get "/institutions/#{ids[index]}.json", '', (obj) ->
              data.push {id: obj.permalink, text: obj.text}
              fetch_data_and_callback(index + 1)

        fetch_data_and_callback(0)

      ajax:
        url: '/institutions/select'
        dataType: "json"
        data: (term, page) ->
          q: term
        results: (data, page) ->
          # use institution permalink as the select2 id
          for obj in data
            obj.id = obj.permalink
            delete obj.permalink

          results: data

    institutions = mconf.Base.getUrlParts(String(window.location)).institutions
    if institutions? and $('#institutions').val() != institutions
      $('#institutions').select2('val', institutions.split(','))

    $('input#institutions').on 'change', ->
      input = $(this)
      baseUrl = $('input.resource-filter').data('load-url')

      params = mconf.Base.getUrlParts(String(window.location))
      if input.val().length > 0
        params.institutions = input.val()
      else
        delete params['institutions']

      history.pushState(params, '', baseUrl + mconf.Base.urlFromParts(params))
      $('input.resource-filter').trigger('update-resources')

    $('input.resource-filter-field').each ->
      input = $(this)
      field = $(this).attr('data-attr-filter')
      baseUrl = $('input.resource-filter').data('load-url')

      $(this).on 'click', ->
        url = new URL(window.location)
        params = mconf.Base.parseQueryString(url.search)
        if $(this).is(':checked')
          params[field] = $(this).val()
          opValue = if params[field] is 'true' then 'false' else 'true'
          opElement = $("input[data-attr-filter='#{field}'][value='#{opValue}']")[0]
          opElement.checked = false if opElement?.checked
        else
          delete params[field]

        url.search = mconf.Base.makeQueryString(params)
        history.pushState(params, '', url.toString())
        $('input.resource-filter').trigger('update-resources')
