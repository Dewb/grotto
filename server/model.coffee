C = 300
B = Math.sin(60 * Math.PI / 180.0) * C
A = C * 0.5

tubeCoords = [

  # inner ring
  [-B, A], 
  [-B, A - C], 
  [0, -C], 
  [B, A - C], 
  [B, A], 
  [0, C], 

  # middle ring  
  [-B * 2, A * 2], 
  [-B * 2, A * 2 - C], 
  [-B * 2, A * 2 - C * 2], 
  [-B, A - C * 2], 
  [0, -C * 2], 
  [B, A - C * 2], 
  [B * 2, A * 2 - C * 2], 
  [B * 2, A * 2 - C], 
  [B * 2, A * 2], 
  [B, A * 3], 
  [0, C * 2], 
  [-B, A * 3],
   
  # outer ring
  [-B * 3, A * 3], 
  [-B * 3, A * 3 - C], 
  [-B * 3, A * 3 - C * 2], 
  [-B * 3, A * 3 - C * 3], 
  [-B * 2, A * 2 - C * 3], 
  [-B, A - C * 3], 
  [0, -C * 3], 
  [B, A - C * 3], 
  [B * 2, A * 2 - C * 3], 
  [B * 3, A * 3 - C * 3], 
  [B * 3, A * 3 - C * 2], 
  [B * 3, A * 3 - C], 
  [B * 3, A * 3], 
  [B * 2, A * 4], 
  [B, A * 5], 
  [0, C * 3], 
  [-B, A * 5], 
  [-B * 2, A * 4]
]

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