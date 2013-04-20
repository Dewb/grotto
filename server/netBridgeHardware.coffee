module.exports = (model) ->

  model.addBeamCallback (tube1, tube2) ->
    console.log("Hardware beam callback executed")