$('.duplicate').click (e) ->

  id = $(this).attr('data')

  $('.activate').hide()
  $('.select-duplicate').show()
  $(this).find('.select-duplicate').hide()

  $('.duplicate').each ->
    other_id = $(this).attr('data')
    if other_id isnt id
      $('<a/>', 'data-confirm': 'yes?', href: "/correct_duplicate?original=#{id}&copy=#{other_id}", text: '... of this one').appendTo($(this))