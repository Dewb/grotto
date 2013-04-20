tubeCoords = undefined
beamCoords = undefined

beamTriggers = []

createGrotto = (scene, pickingGeometry) ->
  i = 0
  j = 0
  
  while i < tubeCoords.length
    position = new THREE.Vector3(tubeCoords[i][0], 0, tubeCoords[i][1])
    rotation = new THREE.Vector3(0, 0, 0)
    scale = new THREE.Vector3(15, 450, 15)
    
    scene.createTube scene, position, rotation, scale
    #scene.createPick "tube",
    #  pickingGeometry, 
    #  new THREE.CylinderGeometry(1, 1, 1, 20, 1), [],
    #  (data) ->,
    #  position, rotation, scale    
    i++
    
  while j < beamCoords.length
    position = new THREE.Vector3(beamCoords[j].x, -100.0, beamCoords[j].y)
    rotation = new THREE.Vector3(0, beamCoords[j].rotation, 0)
    scale = new THREE.Vector3(40, 40, beamCoords[j].length)
    scene.createPick "beam", 
      pickingGeometry,
      new THREE.CubeGeometry(1, 1, 1), beamCoords[j].parents,
      (data) -> now.onBeamBroken data.parents[0], data.parents[1],
      position, rotation, scale    
    j++
  
updateGrotto = (scene) ->
  i = 0
  while i < scene.__lights.length
    lights = scene.__lights
    c0 = lights[i].color.getHSL()
    c0.h += 0.001
    c0.h = 0  if c0.h > 1
    lights[i].color.setHSL c0.h, c0.s, c0.l
    c1 = lights[i + 1].color.getHSL()
    c1.h += 0.001
    c1.h = 0  if c1.h > 1
    lights[i + 1].color.setHSL c1.h, c1.s, c1.l
    i += 2

  while beamTriggers.length > 0
    [tube1, tube2] = beamTriggers.shift()    
    scene.__lights[tube1*2].color.setHSL(0.7, 1.0, 0.5)
    scene.__lights[tube1*2+1].color.setHSL(0.58, 1.0, 0.5)
    scene.__lights[tube2*2].color.setHSL(0.7, 1.0, 0.5)
    scene.__lights[tube2*2+1].color.setHSL(0.58, 1.0, 0.5)
    
now.ready () ->
  tubeCoords = now.tubeCoords
  beamCoords = now.beamCoords
  window.initRenderer(createGrotto, updateGrotto)

now.receiveBreakEvent = (tube1, tube2) ->
  beamTriggers.push([tube1, tube2])
