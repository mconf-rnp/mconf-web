mconf.Institutions or= {}

class mconf.Institutions.InstitutionForm

  @generateSecret: ->
    secret = randomString(32)
    $("#institution_secret").val(secret) if _.isEmpty($("#institution_secret").val())

# Random string with `length` characters
randomString = (length) ->
  length++
  chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
  text = ""
  text += chars.charAt(Math.floor(Math.random() * chars.length)) while length -= 1
  text
