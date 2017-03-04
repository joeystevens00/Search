# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/



$(document).ready ->
  $('#results').dataTable()
@newTorrent = (url) ->
  $.ajaxSetup async: false
  resp = $.post '/api/new_torrent', torrent: url
  console.log resp.responseText
  code = jQuery.parseJSON(resp.responseText)
  if code.success is 0
    $('.success').show().delay(5000).fadeOut()
  else
    $('.fail').show().delay(5000).fadeOut()
  $('#results').dataTable()
  window.location.reload(true); # Can't find a better way to restore the dataTable
  return false

