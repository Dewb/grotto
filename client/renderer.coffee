container = undefined
stats = undefined
camera = undefined
controls = undefined
renderer = undefined

scene = new THREE.Scene()

nextTick = Date.now()
FPS = 60.0
msPerTick = 1000 / FPS
modelUpdateFunction = undefined

pickingData = []
pickingTexture = undefined
pickingScene = undefined
highlightBox = undefined
highlightBeam = undefined

lastPickId = undefined

worldSize = 16000

mouse = new THREE.Vector2()
offset = new THREE.Vector3(10, 10, 10)

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
)

bubbleMaterial = new THREE.ParticleBasicMaterial(
  color: 0xff0000
  size: 8
  opacity: 0.75
  transparent: true
  blending: THREE.AdditiveBlending
  map: THREE.ImageUtils.loadTexture("res/bubble-sprite-64.png")
)

bubbleAttributes =
  size:
    type: 'f'
    value: []
  age:
    type: 'f'
    value: []
  tubeId:
    type: 'f'
    value: []

bubbleUniforms =
  colors:
    type: 'v3v'
    value: []
  texture:
    type: 't'
    value: THREE.ImageUtils.loadTexture("res/bubble-sprite-64.png")
  time:
    type: 'f'
    value: 0.0

bubbleShaderMaterial = new THREE.ShaderMaterial
  uniforms: bubbleUniforms
  attributes: bubbleAttributes
  vertexShader: require('./bubbleShaderVertex')
  fragmentShader: require('./bubbleShaderFragment')
  blending: THREE.AdditiveBlending
  depthTest: true
  transparent: true

reflectionCube = THREE.ImageUtils.loadTextureCube([
  "res/panorama.jpg",
  "res/panorama.jpg",
  "res/black.jpg",
  "res/black.jpg",
  "res/panorama.jpg",
  "res/panorama.jpg"
])
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

applyPRSMatrix = (geom, position, rotation, scale) ->
  m = new THREE.Matrix4()
  m.makeFromPositionEulerScale(position, rotation, "XYZ", scale)
  geom.applyMatrix(m)

applyVertexColors = (g, c) ->
  g.faces.forEach (f) ->
    n = (if (f instanceof THREE.Face3) then 3 else 4)
    j = 0
    while j < n
      f.vertexColors[j] = c
      j++

scene.createBubbles = (particleGeometry, id, bottom, top, position, rotation, scale) ->
  bubbleRadius = 0.55
  bubbleR = 8
  bubbleH = 16

  particles = new THREE.Geometry()

  h = 0
  while (h < bubbleH)
    r = 0
    while (r < bubbleR)
      theta = r/bubbleR*Math.PI*2
      pt = new THREE.Vector3(
        bubbleRadius * Math.cos(theta) + Math.random() * 0.15
        bottom + h/bubbleH*(top-bottom) + Math.random() * 0.05
        bubbleRadius * Math.sin(theta) + Math.random() * 0.15
      )
      particles.vertices.push pt
      bubbleAttributes.tubeId.value.push id
      bubbleAttributes.age.value.push 0
      bubbleAttributes.size.value.push 2.0 + Math.random() * 10.0

      r++
    h++

  applyPRSMatrix particles, position, rotation, scale
  THREE.GeometryUtils.merge particleGeometry, particles

scene.createTube = (position, rotation, scale) ->
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

  @add shell
  @add tankMesh

  c1 = new THREE.Color()
  c1.setHSL 0.7, 1.0, 0.5
  c2 = new THREE.Color()
  c2.setHSL 0.58, 1.0, 0.5

  bubbleUniforms.colors.value.push new THREE.Vector3(c1.r, c1.g, c1.b)
  bubbleUniforms.colors.value.push new THREE.Vector3(c2.r, c2.g, c2.b)

  topLight = new THREE.PointLight(c1.getHex(), 5.0, scale.y / 15.0)
  bottomLight = new THREE.PointLight(c2.getHex(), 5.0, scale.y / 15.0)
  topPosition = position.clone()
  topPosition.y = (0.5 - topHeight - 0.01) * scale.y
  bottomPosition = position.clone()
  bottomPosition.y = (-0.5 + bottomHeight + 0.01) * scale.y
  applyPRS topLight, topPosition, rotation, scale
  applyPRS bottomLight, bottomPosition, rotation, scale
  @add topLight
  @add bottomLight

scene.createPick = (type, pickingGeometry, shape, parents, callback, position, rotation, scale) ->
  pickingColor = new THREE.Color(pickingData.length + 1)
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
    callback: callback
  }

scene.getNumLights = () ->
	return @__lights.length

scene.getLightColor = (index) ->
  return @__lights[index].color

scene.setLightColor = (index, c) ->
  @__lights[index].color.setRGB(c.r, c.g, c.b)
  bubbleUniforms.colors.value[index].set(c.r, c.g, c.b)

applyVertexColors = (g, c) ->
  g.faces.forEach (f) ->
    n = (if (f instanceof THREE.Face3) then 3 else 4)
    j = 0
    while j < n
      f.vertexColors[j] = c
      j++

initRenderer = (createFunction, updateFunction) ->
  container = document.getElementById("container")

  camera = new THREE.PerspectiveCamera(
    70,
    window.innerWidth / window.innerHeight,
    1,
    10000
  )
  camera.position.z = 1500

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

  pickingScene = new THREE.Scene()
  pickingTexture = new THREE.WebGLRenderTarget(window.innerWidth, window.innerHeight)
  pickingTexture.generateMipmaps = false

  light = new THREE.SpotLight(0xffffff, 0.9)
  light.position.set 0, 500, 2000

  ground = new THREE.Mesh(
    new THREE.PlaneGeometry(worldSize*1.5, worldSize*1.5),
    groundMaterial
  )
  ground.rotation.x = -Math.PI / 2
  ground.position.y = -0.5 * 465
  scene.add ground

  skyMesh = new THREE.Mesh(
    new THREE.CylinderGeometry(worldSize/2.0, worldSize/2.0, worldSize/2.0, 24, 1),
    skyMaterial
  )
  scene.add skyMesh

  pickingGeometry = new THREE.Geometry()
  bubbleGeometry = new THREE.Geometry()

  createFunction(scene, bubbleGeometry, pickingGeometry)

  if false
    bubbleSystem = new THREE.ParticleSystem(bubbleGeometry, bubbleMaterial)
  else
    bubbleSystem = new THREE.ParticleSystem(bubbleGeometry, bubbleShaderMaterial)

  bubbleSystem.sortParticles = true
  scene.add bubbleSystem

  pickingScene.add new THREE.Mesh(pickingGeometry, pickingMaterial)

  highlightBox = new THREE.Mesh(
    new THREE.CylinderGeometry(0.8, 1.05, 1, 20, 1),
    highlightMaterial
  )
  scene.add highlightBox

  highlightBeam = new THREE.Mesh(
    new THREE.CubeGeometry(1, 1, 1),
    beamMaterial
  )
  scene.add highlightBeam

  projector = new THREE.Projector()

  if Detector.webgl
    renderer = new THREE.WebGLRenderer(
      antialias: true
    )
    renderer.sortObjects = false
    renderer.setSize window.innerWidth, window.innerHeight
    renderer.setClearColor 0xffffff, 1.0
  else
    renderer = new THREE.CanvasRenderer()
    container.innerHTML = """
      <div style="padding: 20px; background-color: red; top: 200px; position: relative;">
      <a href="http://get.webgl.org">Oh no! Your browser does not appear to support WebGL,
      which is required for this simulator. Click here to find out more.</a></div>
    """

  container.appendChild renderer.domElement
  stats = new Stats()
  stats.domElement.style.position = "absolute"
  stats.domElement.style.top = "0px"
  container.appendChild stats.domElement
  renderer.domElement.addEventListener "mousemove", onMouseMove

  modelUpdateFunction = updateFunction
  animate()

onMouseMove = (e) ->
  mouse.x = e.clientX
  mouse.y = e.clientY

animate = ->
  requestAnimationFrame animate

  ticks = 0
  currentTime = Date.now()
  if currentTime - nextTick > 60 * msPerTick
    nextTick = currentTime - msPerTick

  while currentTime > nextTick
    modelUpdateFunction(scene)
    bubbleUniforms.time.value += 0.2
    nextTick += msPerTick
    ticks++

  if ticks
    render()
    stats.update()

pick = ->
  # render the picking scene off-screen
  renderer.render pickingScene, camera, pickingTexture
  gl = renderer.getContext()

  # read the pixel under the mouse from the texture
  pixelBuffer = new Uint8Array(4)
  gl.readPixels(
    mouse.x,
    pickingTexture.height - mouse.y,
    1, 1, gl.RGBA, gl.UNSIGNED_BYTE,
    pixelBuffer
  )

  # interpret the pixel as an ID
  id = (pixelBuffer[0] << 16) | (pixelBuffer[1] << 8) | (pixelBuffer[2]) - 1

  if id == lastPickId
    return

  lastPickId = id
  data = pickingData[id]
  if data

    # move our highlightBox so that it surrounds the picked object
    if data.type == "tube" and data.position and data.rotation and data.scale
      highlightBox.position.copy data.position
      highlightBox.rotation.copy data.rotation
      highlightBox.scale.copy(data.scale).add offset
      highlightBox.visible = true
      highlightBeam.visible = false
      data.callback(data)
    if data.type == "beam" and data.position and data.rotation and data.scale
      highlightBeam.position.copy data.position
      highlightBeam.rotation.copy data.rotation
      highlightBeam.scale.copy(data.scale).add offset
      highlightBeam.visible = true
      highlightBox.visible = false
      data.callback(data)
  else
    highlightBox.visible = false
    highlightBeam.visible = false

render = ->
  controls.update()
  if !controls.isOperationActive()
    pick()
  renderer.render scene, camera


exports.initRenderer = initRenderer
