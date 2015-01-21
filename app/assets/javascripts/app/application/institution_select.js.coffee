# Transforms a simple input into a select box to query via ajax and select
# an institution.
#
# Example:
#
# = simple_form_for @space do |f|
#   = f.input :institution_id, required: false, input_html: { :value => @institution.id, :class => "institution-select", :data => { :"institution-select-placeholder" => I18n.t("spaces.edit.institution_placeholder"), :"institution-name" => @institution.name } }

urlInstitutions = '/institutions/select.json'

class mconf.InstitutionSelect

  @bind: ->
    $("input.institution-select").each ->
      $target = $(this)
      $target.select2
        minimumInputLength: 0
        placeholder: $target.data("institution-select-placeholder")
        width: 'resolve'
        multiple: false
        allowClear: true
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

$ ->
  mconf.InstitutionSelect.bind()
