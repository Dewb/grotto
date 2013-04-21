generateHexagon = (radius, nodesPerSide) ->
  corners = []
  i = 0
  while i < 6
    corners.push [
      -radius * Math.cos(2 * Math.PI * (i/6) + Math.PI/6),
      -radius * Math.sin(2 * Math.PI * (i/6) + Math.PI/6)
      ]
    i++

  allNodes = []
  i = 0
  while i < 6
    j = 0
    allNodes.push corners[i]
    while j < nodesPerSide
      prev = corners[i]
      next = corners[(i+1)%6]
      allNodes.push [
        prev[0] + (j+1) / (nodesPerSide + 1) * (next[0] - prev[0]),
        prev[1] + (j+1) / (nodesPerSide + 1) * (next[1] - prev[1]),
        ]
      j++
    i++

  return allNodes

tubeCoords = []

tubeCoords = tubeCoords.concat generateHexagon(300, 0)
tubeCoords = tubeCoords.concat generateHexagon(600, 1)
tubeCoords = tubeCoords.concat generateHexagon(900, 2)

makebeam = (m, n) ->
  dx = tubeCoords[m][0]-tubeCoords[n][0]
  dy = tubeCoords[m][1]-tubeCoords[n][1]

  return {
    x: (tubeCoords[m][0]+tubeCoords[n][0])/2.0,
    y: (tubeCoords[m][1]+tubeCoords[n][1])/2.0,
    rotation: Math.atan2(dx, dy)
    length: Math.sqrt(Math.pow(dx, 2) + Math.pow(dy, 2))
    parents: [m, n]
  }

beamCoords = []

beamstart = 0
beamend = 18
while beamstart < 36
  if beamstart < 6
    beamCoords.push(makebeam(beamstart, (beamstart+1)%6))
    beamCoords.push(makebeam(beamstart, if beamstart == 0 then 17 else beamstart*2+5))
    beamCoords.push(makebeam(beamstart, beamstart*2+6))
    beamCoords.push(makebeam(beamstart, beamstart*2+7))
  else if beamstart < 18
    beamCoords.push(makebeam(beamstart, ((beamstart-5)%12)+6))
    if beamstart % 2 == 0
      beamCoords.push(makebeam(beamstart, if beamstart == 6 then 35 else beamend++))
    beamCoords.push(makebeam(beamstart, beamend++))
    beamCoords.push(makebeam(beamstart, beamend))
  else
    beamCoords.push(makebeam(beamstart, ((beamstart-17)%18)+18))
  beamstart++


beamCallbacks = []
addBeamCallback = (callback) ->
  beamCallbacks.push(callback)

onBeamBroken = (tube1, tube2) ->
  console.log('Beam ' + tube1 + '-' + tube2 + ' broken')
  i = 0
  while i < beamCallbacks.length
    beamCallbacks[i](tube1, tube2)
    i++

exports.tubeCoords = tubeCoords
exports.beamCoords = beamCoords
exports.onBeamBroken = onBeamBroken
exports.addBeamCallback = addBeamCallback
