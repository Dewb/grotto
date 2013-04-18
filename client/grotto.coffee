container = undefined
stats = undefined
camera = undefined
controls = undefined
scene = undefined
renderer = undefined

pickingData = []
pickingTexture = undefined
pickingScene = undefined
highlightBox = undefined
highlightBeam = undefined

mouse = new THREE.Vector2()
offset = new THREE.Vector3(10, 10, 10)

worldSize = 16000

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
while beamstart < 6
  beamCoords.push(makebeam(beamstart, (beamstart+1)%6))
  beamCoords.push(makebeam(beamstart, if beamstart == 0 then 17 else beamstart*2+5))
  beamCoords.push(makebeam(beamstart, beamstart*2+6))
  beamCoords.push(makebeam(beamstart, beamstart*2+7))
  beamstart++

beamstart = 6
beamend = 18
while beamstart < 18
  beamCoords.push(makebeam(beamstart, ((beamstart-5)%12)+6))
  if beamstart % 2 == 0
    beamCoords.push(makebeam(beamstart, if beamstart == 6 then 35 else beamend++))
  beamCoords.push(makebeam(beamstart, beamend++))
  beamCoords.push(makebeam(beamstart, beamend))
  beamstart++

beamstart = 18
while beamstart < 36
  beamCoords.push(makebeam(beamstart, ((beamstart-17)%18)+18))
  beamstart++

shellMaterial = new THREE.MeshBasicMaterial(
  color: 0x202535
  shading: THREE.SmoothShading
  vertexColors: THREE.VertexColors
)

tankMaterial = new THREE.MeshLambertMaterial(
  color: 0xffffff
  opacity: 0.65
  transparent: true
  shading: THREE.SmoothShading
  side: THREE.BackSide
  vertexColors: THREE.VertexColors
)

stoneTexture = THREE.ImageUtils.loadTexture("res/stone.jpg")
stoneTexture.wrapS = THREE.RepeatWrapping
stoneTexture.wrapT = THREE.RepeatWrapping
stoneTexture.repeat.set 80, 30

groundMaterial = new THREE.MeshBasicMaterial(
  color: 0x262617
  depthTest: true
  depthWrite: true
  map: stoneTexture
  transparency: 1.0
  transparent: false
  vertexColors: false
  fog: true
)

pickingMaterial = new THREE.MeshBasicMaterial(vertexColors: THREE.VertexColors)

highlightMaterial = new THREE.MeshBasicMaterial(
  color: 0xffff00
  opacity: 0.6
  transparent: true
  side: THREE.BackSide
)

beamMaterial = new THREE.MeshBasicMaterial(
  color: 0xff0000
  opacity: 0.2
  transparent: true
  side: THREE.BothSides
)

reflectionCube = THREE.ImageUtils.loadTextureCube(["res/panorama.jpg", "res/panorama.jpg", "res/black.jpg", "res/black.jpg", "res/panorama.jpg", "res/panorama.jpg"])
shader = THREE.ShaderLib["cube"]
shader.uniforms["tCube"].value = reflectionCube
skyMaterial = new THREE.ShaderMaterial(
  fragmentShader: shader.fragmentShader
  vertexShader: shader.vertexShader
  uniforms: shader.uniforms
  depthWrite: false
  side: THREE.BackSide
)

transform = (geom, x, y, z) ->
  transM = new THREE.Matrix4()
  transM.makeTranslation x, y, z
  geom.applyMatrix transM
  
applyPRS = (geom, position, rotation, scale) ->
  geom.position.copy position
  geom.rotation.copy rotation
  geom.scale.copy scale
  
createTube = (scene, position, rotation, scale) ->
  topHeight = 0.03
  bottomHeight = 0.3
  top = new THREE.CylinderGeometry(1, 1, topHeight, 20, 1)
  bottom = new THREE.CylinderGeometry(1, 1.3, bottomHeight, 20, 1)
  tank = new THREE.CylinderGeometry(1, 1, 1 - topHeight - bottomHeight - 0.001, 20, 1)
  transform top, 0, 0.5 - topHeight / 2.0, 0
  transform bottom, 0, -0.5 + bottomHeight / 2.0, 0
  transform tank, 0, -0.5 + bottomHeight + (1 - topHeight - bottomHeight) / 2.0, 0

  geom = new THREE.Geometry()
  THREE.GeometryUtils.merge geom, top
  THREE.GeometryUtils.merge geom, bottom

  shell = new THREE.Mesh(geom, shellMaterial)
  applyPRS shell, position, rotation, scale
  tankMesh = new THREE.Mesh(tank, tankMaterial)
  applyPRS tankMesh, position, rotation, scale
  scene.add shell
  scene.add tankMesh
  
  c1 = new THREE.Color()
  c1.setHSL 0.7, 1.0, 0.5
  c2 = new THREE.Color()
  c2.setHSL 0.58, 1.0, 0.5
  
  topLight = new THREE.PointLight(c1.getHex(), 5.0, scale.y / 15.0)
  bottomLight = new THREE.PointLight(c2.getHex(), 5.0, scale.y / 15.0)
  topPosition = position.clone()
  topPosition.y = (0.5 - topHeight - 0.01) * scale.y
  bottomPosition = position.clone()
  bottomPosition.y = (-0.5 + bottomHeight + 0.01) * scale.y
  applyPRS topLight, topPosition, rotation, scale
  applyPRS bottomLight, bottomPosition, rotation, scale
  scene.add topLight
  scene.add bottomLight
  
createPick = (type, shape, parents, pickingGeometry, pickingData, position, rotation, scale) ->
  pickingColor = new THREE.Color(pickingData.length)
  applyVertexColors shape, pickingColor
  pickingBounds = new THREE.Mesh(shape)
  pickingBounds.position.copy position
  pickingBounds.rotation.copy rotation
  pickingBounds.scale.copy scale
  THREE.GeometryUtils.merge pickingGeometry, pickingBounds
  pickingData.push {
    position: position
    rotation: rotation
    scale: scale
    type: type
    parents: parents
  }
  
applyVertexColors = (g, c) ->
  g.faces.forEach (f) ->
    n = (if (f instanceof THREE.Face3) then 3 else 4)
    j = 0
    while j < n
      f.vertexColors[j] = c
      j++

init = ->
  container = document.getElementById("container")
  camera = new THREE.PerspectiveCamera(70, window.innerWidth / window.innerHeight, 1, 10000)
  camera.position.z = 1000
  controls = new THREE.OrbitControls(camera)
  controls.rotateSpeed = 1.0
  controls.zoomSpeed = 1.2
  controls.panSpeed = 0.8
  controls.noZoom = false
  controls.noPan = true
  controls.staticMoving = true
  controls.dynamicDampingFactor = 0.3
  controls.minDistance = 200
  controls.maxDistance = 1800
  controls.maxPolarAngle = Math.PI * 0.499
  scene = new THREE.Scene()
  pickingScene = new THREE.Scene()
  pickingTexture = new THREE.WebGLRenderTarget(window.innerWidth, window.innerHeight)
  pickingTexture.generateMipmaps = false
  
  light = new THREE.SpotLight(0xffffff, 0.9)
  light.position.set 0, 500, 2000
  #scene.add( light );				
  #scene.add( new THREE.AmbientLight( 0x555555, 0.2 ) );

  ground = new THREE.Mesh(new THREE.PlaneGeometry(worldSize, worldSize), groundMaterial)
  ground.rotation.x = -Math.PI / 2
  ground.position.y = -0.5 * 465
  scene.add ground
  skyMesh = new THREE.Mesh(new THREE.CylinderGeometry(worldSize/2.0, worldSize/2.0, worldSize/2.0, 36, 1), skyMaterial)
  scene.add skyMesh
  pickingGeometry = new THREE.Geometry()
  i = 0
  j = 0
  
  while i < tubeCoords.length
    position = new THREE.Vector3(tubeCoords[i][0], 0, tubeCoords[i][1])
    rotation = new THREE.Vector3(0, 0, 0)
    scale = new THREE.Vector3(15, 450, 15)
    
    createTube scene, position, rotation, scale
    createPick "tube", new THREE.CylinderGeometry(1, 1, 1, 20, 1), [],
      pickingGeometry, pickingData, position, rotation, scale    
    i++
    
  while j < beamCoords.length
    position = new THREE.Vector3(beamCoords[j].x, -100.0, beamCoords[j].y)
    rotation = new THREE.Vector3(0, beamCoords[j].rotation, 0)
    scale = new THREE.Vector3(40, 40, beamCoords[j].length)
    createPick "beam", new THREE.CubeGeometry(1, 1, 1), beamCoords[j].parents,
      pickingGeometry, pickingData, position, rotation, scale    
    j++
    
  pickingScene.add new THREE.Mesh(pickingGeometry, pickingMaterial)
  
  highlightBox = new THREE.Mesh(new THREE.CylinderGeometry(0.8, 1.05, 1, 20, 1), highlightMaterial)
  scene.add highlightBox
  
  highlightBeam = new THREE.Mesh(new THREE.CubeGeometry(1, 1, 1), beamMaterial)
  scene.add highlightBeam
  
  projector = new THREE.Projector()
  
  if Detector.webgl
    renderer = new THREE.WebGLRenderer(
      antialias: true
      clearColor: 0x000000
    )
    renderer.sortObjects = false
    renderer.setSize window.innerWidth, window.innerHeight
  else
    renderer = new THREE.CanvasRenderer(clearColor: 0x000000)
    container.innerHTML = "<div style=\"padding: 20px; background-color: red; top: 200px; position: relative;\"><a href=\"http://get.webgl.org\">Oh no! Your browser does not appear to support WebGL, which is required for this simulator. Click here to find out more.</a></div>"
  
  container.appendChild renderer.domElement
  stats = new Stats()
  stats.domElement.style.position = "absolute"
  stats.domElement.style.top = "0px"
  container.appendChild stats.domElement
  renderer.domElement.addEventListener "mousemove", onMouseMove

onMouseMove = (e) ->
  mouse.x = e.clientX
  mouse.y = e.clientY

animate = ->
  requestAnimationFrame animate
  render()
  stats.update()
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

pick = ->  
  #render the picking scene off-screen
  renderer.setClearColorHex 0xffffff
  renderer.render pickingScene, camera, pickingTexture
  renderer.setClearColorHex 0x000000
  gl = renderer.getContext()
  
  #read the pixel under the mouse from the texture
  pixelBuffer = new Uint8Array(4)
  gl.readPixels mouse.x, pickingTexture.height - mouse.y, 1, 1, gl.RGBA, gl.UNSIGNED_BYTE, pixelBuffer
  
  #interpret the pixel as an ID
  id = (pixelBuffer[0] << 16) | (pixelBuffer[1] << 8) | (pixelBuffer[2])
  data = pickingData[id]
  if data
    
    #move our highlightBox so that it surrounds the picked object
    if data.type == "tube" and data.position and data.rotation and data.scale
      highlightBox.position.copy data.position
      highlightBox.rotation.copy data.rotation
      highlightBox.scale.copy(data.scale).add offset
      highlightBox.visible = true
      highlightBeam.visible = false
    if data.type == "beam" and data.position and data.rotation and data.scale
      highlightBeam.position.copy data.position
      highlightBeam.rotation.copy data.rotation
      highlightBeam.scale.copy(data.scale).add offset
      highlightBeam.visible = true
      highlightBox.visible = false
      now.breakBeam data.parents[0], data.parents[1]
  else
    highlightBox.visible = false
    highlightBeam.visible = false

render = ->
  controls.update()
  pick()
  renderer.render scene, camera

init()
animate()

now.receiveBreakBeam = (tube1, tube2) ->
  scene.__lights[tube1*2].color.setHSL(0.7, 1.0, 0.5)
  scene.__lights[tube1*2+1].color.setHSL(0.58, 1.0, 0.5)
  scene.__lights[tube2*2].color.setHSL(0.7, 1.0, 0.5)
  scene.__lights[tube2*2+1].color.setHSL(0.58, 1.0, 0.5)