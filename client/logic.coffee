tubeCoords = undefined
beamCoords = undefined

beamTriggers = []

createGrotto = (scene, bubbleGeometry, pickingGeometry) ->
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
    scene.createBubbles bubbleGeometry, i, -0.19, 0.46, position, rotation, scale  
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
  
  topStartColor = new THREE.Color()
  topStartColor.setHSL(0.7, 1.0, 0.5)
  botStartColor = new THREE.Color()
  botStartColor.setHSL(0.58, 1.0, 0.5)
  
  while beamTriggers.length > 0
    [tube1, tube2] = beamTriggers.shift()    
    scene.setLightColor(tube1*2, topStartColor)
    scene.setLightColor(tube1*2+1, botStartColor)
    scene.setLightColor(tube2*2, topStartColor)
    scene.setLightColor(tube2*2+1, botStartColor)
    
  i = 0
  while i < scene.getNumLights()
    c = scene.getLightColor(i)
    c0 = c.getHSL()
    c0.h += 0.001
    c0.h = 0  if c0.h > 1    
    c.setHSL(c0.h, c0.s, c0.l)
    scene.setLightColor(i, c)
    i++
    
now.ready () ->
  tubeCoords = now.tubeCoords
  beamCoords = now.beamCoords
  window.initRenderer(createGrotto, updateGrotto)

now.receiveBreakEvent = (tube1, tube2) ->
  beamTriggers.push([tube1, tube2])
