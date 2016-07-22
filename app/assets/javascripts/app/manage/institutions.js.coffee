#= require "../institutions/_institution_form"

$ ->
  if isOnPage 'manage', 'institutions'

    mconf.Resources.addToBind ->
      mconf.Institutions.InstitutionForm.generateSecret()
