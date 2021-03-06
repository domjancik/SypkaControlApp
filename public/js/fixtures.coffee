$(document).ready ->  

	FLAGS = [ 'o', 'down', 'up' ]

	createElement = ( elem ) ->
		$(document.createElement elem)

	container3d = $('#container')
	fixtureGroups = []

	fixture_json_url = ->
		'fixtures.json?t=' + (new Date()).getTime()

	values_json_url = ->
		'values.json?t=' + (new Date()).getTime()

	scene_json_url = ( filename ) ->
		"scenes/#{filename}?t=" + (new Date()).getTime()

	getIntensityColor = ( value ) ->
		colorValue = Math.round(255 * value)
		"rgb(#{colorValue}, #{colorValue}, #{colorValue})"

	# Dimmer widget
	$.widget 'xyz.dimmer',
		options:
			steps: 10

		_create: ->
			for i in [0..this.options.steps]
				this.element.append this._createButton i

		_createButton: ( index ) ->
			intensity = 1 / this.options.steps * index

			d = $(document.createElement 'div')
			d.addClass 'dimmer-button'
			d.css
				width: "#{100 / (this.options.steps + 1)}%"
				background: getIntensityColor intensity

			d.click ->
				setDimmer intensity
			

	# Fixture Widget
	$.widget 'xyz.fixture',
		options:
			name: 'NA'
			index: 0
			value: 0.5
			flags: new Set()
			selected: false

		_create: ->
			this.element.addClass 'fixture'

			this.element.click this, (ev) ->
				ev.data.options.selected = !ev.data.options.selected
				ev.data.element.toggleClass 'selected', ev.data.options.selected

			this._update()

		_update: ->
			# console.log 'fixture update'

			this.element.css
				'background-color': getIntensityColor this.options.value

			caption = ""
			for flag in Array.from this.options.flags
				console.log caption
				caption += "#{flag} "

			this.element.html(caption)

		_constrain: ( value ) ->
			return Math.max(Math.min( value, 1 ), 0)

		value: ( value ) ->
			if value == undefined
				return this.options.value

			this.options.value = this._constrain value
			this._update()
			this

		flags: ( flags ) ->
			if flags == undefined
				return Array.from this.options.flags

			this.options.flags = new Set( flags )

			this._update()
			this

		addFlag: ( flag ) ->
			console.log "Adding #{flag}"
			this.options.flags.add flag
			this._update()
			this

		deleteFlag: ( flag ) ->
			this.options.flags.delete flag
			this._update()
			this

		clearFlags: ->
			this.options.flags.clear()
			this._update()
			this

		optionsObject: -> this.options

	$.fn.group = (fixture) ->
		this.addClass 'group'
		this.data
			name: fixture.name
		
		# this.html(fixture.name).group()

		this.click this, (ev) ->
			fgs = getFixtureGroupsByName ev.data.data 'name'
			# fixtures = fgs.children('.fixture')			

			console.log ev.data.data 'name'
			console.log fgs

			console.log 'group click'
			hasSelected = false

			for fg in fgs
				if fg.children('.selected').length > 0
					hasSelected = true
					break
				
			
			console.log hasSelected

			for fg in fgs
				fg.children('.fixture').toggleClass 'selected', !hasSelected
			
			#hasSelected = ev.data.siblings('.selected').length > 0
			#console.log hasSelected
			#ev.data.siblings('.fixture').toggleClass 'selected', !hasSelected

		this

	$.fn.fixtureGroup = (fixture, segment) ->
		# console.log this

		settings = $.extend 
			x: 0
			y: 0
			z: 0
			rotX: 0
			rotY: 0
			rotZ: 0
			flags: [],
			segment
		
		fixtureTopData = getBaseData fixture
		delete fixtureTopData['segments']
		settings = $.extend settings, fixtureTopData


		this.data(settings)

		this.addClass 'fixtureGroup'
		this.addClass segment.type
		for flag in settings.flags
			this.addClass flag
		this.addClass 'floor' + segment.floor
		this.data segment

		this.updateTransform = ->
			this.css
				transform: "translate3d(#{this.data().x}vw, #{this.data().y}vw, #{this.data().z}vw) rotateX(#{this.data().rotX}deg) rotateY(#{this.data().rotY}deg) rotateZ(#{this.data().rotZ}deg)"

		this.updateTransform()

		this.hasSelected = ->
			this.children('.selected').length > 0

		this.translate = (x, y, z = 0) ->
			this.data().x += x
			this.data().y += y
			this.data().z += z
			this.updateTransform()

		this.rotate = (x, y, z = 0) ->
			this.data().rotX += x
			this.data().rotY += y
			this.data().rotZ += z
			this.updateTransform()

		this


	add_fixture = (fixture) ->
		# console.log fixture
		for segment, i in fixture.segments
			# console.log segment
			d = document.createElement 'div'
			# console.log "Adding #{fixture.name}"
			fixtureGroups.push $(d).fixtureGroup fixture, segment

			if (segment.count > 1 || fixture.segments.length > 1) && i == 0
				g = document.createElement 'div'
				$(g).group fixture
				$(d).append g

			
			for i in [0...segment.count]
				f = document.createElement 'div'
				$(f).fixture
					name: fixture.name
					index: i
				d.append(f)
			
			$('#container').append(d)

	# $('input[type="range"]').rangeslider
	# 	onSlide: (position, value) -> console.log 'hello'

	clearSelection = -> $('.fixture').removeClass 'selected'
	selected = -> $('.selected')
	allFixtures = -> $('.fixture')

	invertSelection = -> $('.fixture').toggleClass 'selected'

	# UI
	# Set dimmer value, expects values between 0-1, triggers dimmer:change event
	setDimmer = ( value ) ->
		# fixtures = if selected().length > 0 then selected() else allFixtures()
		fixtures = selected()

		fixtures.fixture('value', value)
		$(window).trigger 'dimmer:change'# TODO move this to fixtures? (all need to be handled at once though)

	addFlag = ( flag ) ->
		fixtures = selected()
		fixtures.fixture('addFlag', flag)
		$(window).trigger 'dimmer:change' # TODO separate event for flags?

	clearFlags = ->
		console.log 'Clearing flags'
		fixtures = selected()
		fixtures.fixture('clearFlags')
		$(window).trigger 'dimmer:change' # TODO separate event for flags?

	initFlags = ->
		flagsContainer = $('#flags')
		flagButton = $('#flags input')

		for flag in FLAGS
			do ->
				scopedFlag = flag
				flagButton
					.clone()
					.val(flag)
					.click ->
						addFlag scopedFlag
					.appendTo flagsContainer

		$('#flagsClear').click clearFlags
		
	initFlags()

	$('#reset').click clearSelection
	$('#invert').click invertSelection
	$('.dimmer').dimmer()
	$('#dimmer').change (ev) ->
		value = ev.target.value
		setDimmer value / 100

	$("#mode").click ->
		addFlag 'o'		

	$(document).bind 'keydown', 'esc', clearSelection

	showFloor = (floor) ->
		$('.floor1').hide()
		$('.floor2').hide()
		$('.floor3').hide()
		
		$(".floor#{floor}").show()

		$('#floor').html floor

	$.get fixture_json_url(), (data) ->
		console.log "Loading fixtures"
		console.log data
		for name, fixture of data.fixtures
			console.log "loaded #{name}"
			add_fixture fixture

		showFloor 1

	getFixtureGroupsByName = ( name ) ->
		# console.log 'looking up ' + name
		fgs = $('.fixtureGroup')

		fixtureGroupsArr = []

		found = false
		for fixtureGroup in fgs
			# console.log $(fixtureGroup).data('name')
			if $(fixtureGroup).data('name') == name
				fixtureGroupsArr.push $(fixtureGroup)
				found = true
				continue
			if found then break # Fixtures with same names are expected to be located next to each other

		fixtureGroupsArr

	loadValues = ( path, callback = undefined ) ->
		$.get path, ( data ) ->
			console.log 'load'
			console.log data
			for name, values of data
				# console.log name
				fgs = getFixtureGroupsByName name
				# console.log fgs
				i = 0

				for fg in fgs
					fg.children('.fixture').each ->
						# console.log values[i]
						$(this).fixture('value', values[i].v) # TODO move logic to fixtureGroup Widget
						$(this).fixture('flags', values[i].f)
						i++

			callback() if callback?

	loadValues values_json_url()

	$('#floor1').click ->
		showFloor 1
	$('#floor2').click ->
		showFloor 2
	$('#floor3').click ->
		showFloor 3

	# Scene management

	saveScene = ->
		name = prompt 'Scene name'
		saveSceneCommand name

	showScenes = ( scenes ) ->
		$('.scenes__list').html ''

		for scene in scenes
			li = createElement 'li'
			ul = createElement 'ul'

			loadLi = createElement 'li'
			loadAnchor = createElement 'a'
			deleteLi = createElement 'li'
			deleteAnchor = createElement 'a'

			loadAnchor.attr
				href: '#'

			deleteAnchor.attr
				href: '#'

			strippedName = scene.substring(0, scene.lastIndexOf('.json'))

			loadAnchor.html strippedName
			deleteAnchor.html 'X'

			loadLi.append loadAnchor
			deleteLi.append deleteAnchor
			ul.append loadLi
			ul.append deleteLi
			li.append ul

			ul.addClass 'scenes__list__scene'
			loadLi.addClass 'scenes__list__scene__name'
			deleteLi.addClass 'scenes__list__scene__delete'
			
			do -> # CoffeeScript scope hack :D
				clickScene = scene
				loadAnchor.click (ev) ->
					ev.preventDefault()
					loadScene clickScene
				deleteAnchor.click (ev) ->
					ev.preventDefault()
					deleteScene clickScene
			$('.scenes__list').append li

		$('.scenes').show()

	loadScene = ( name ) ->
		console.log "Loading scene #{name}"
		loadValues scene_json_url(name), ->
			$(window).trigger 'dimmer:change'
		closeSceneList()

	deleteScene = ( name ) ->
		console.log "Deleting scene #{name}"
		deleteSceneCommand name
		closeSceneList()
		listScenes()

	listScenes = (ev) ->
		ev.preventDefault() if ev?
		listScenesCommand()

	closeSceneList = (ev) ->
		ev.preventDefault() if ev?
		$('.scenes').hide()

	$('#saveScene').click saveScene
	$('#loadScene').click listScenes
	$('#closeScenes').click closeSceneList

	closeSceneList()

	# Navmap

	updateOrigin = ->
		midX = $(window).width() / 2 + $(window).scrollLeft()
		midY = $(window).height() / 2 + $(window).scrollTop()
		container3d.css
			'perspective-origin': "#{midX}px #{midY}px"

	updateNavmap = ->
		if navlock then return

		mapElem = $('.navmap')
		posElem = $('.navmap__position')

		topPercent = $(window).scrollTop() / ($(document).height() - $(window).height())
		top = (mapElem.height() - posElem.height()) * topPercent

		posElem.css
			top: "#{top}px"

	navlock = false;
	navDrag = false;

	navmapMove = (ev) ->
		mapElem = $('.navmap')
		posElem = $('.navmap__position')
		clickY = ev.originalEvent.y - mapElem.position().top

		topPercent = clickY / (mapElem.height() - posElem.height())
		top = ($(document).height() - $(window).height()) * topPercent

		navlock = true;
		console.log "scroll to #{top}"
		$(window).scrollTop top
		navlock = false;

	navmapClick = (ev) ->
		navmapDown(ev)
		navmapMove(ev)
		navmapUp(ev)

	navmapDown = (ev) ->
		navDrag = true

	navmapUp = (ev) ->
		navDrag = false

	
	$(window).scroll updateOrigin
	$(window).scroll updateNavmap
	
	# $('.navmap').mousemove navmapMove
	# $('.navmap').mousedown navmapDown
	# $('.navmap').mouseup navmapUp

	# $('.navmap').on('touchmove', navmapMove)
	# $('.navmap').on('touchstart', navmapDown)
	# $('.navmap').on('touchend', navmapUp)
	$('.navmap').click navmapMove

	updateOrigin()

	translateSelected = (x, y, z) ->
		for fg in fixtureGroups
			if fg.hasSelected()
				fg.translate(x, y, z)

	translateSelectedOnKey = (key, x, y, z = 0) ->
		$(document).bind 'keydown', key, (ev) ->
			ev.preventDefault()
			translateSelected x, y, z

	rotateSelected = (x, y, z) ->
		for fg in fixtureGroups
			if fg.hasSelected()
				fg.rotate(x, y, z)

	rotateSelectedOnKey = (key, x, y, z = 0) ->
		$(document).bind 'keydown', key, (ev) ->
			ev.preventDefault()
			rotateSelected x, y, z

	translateSelectedOnKey 'right', 5, 0
	translateSelectedOnKey 'left', -5, 0
	translateSelectedOnKey 'up', 0, -5
	translateSelectedOnKey 'down', 0, 5
	translateSelectedOnKey 'shift+right', 20, 0
	translateSelectedOnKey 'shift+left', -20, 0
	translateSelectedOnKey 'shift+up', 0, -20
	translateSelectedOnKey 'shift+down', 0, 20
	translateSelectedOnKey 'ctrl+up', 0, 0, 5
	translateSelectedOnKey 'ctrl+down', 0, 0, -5
	rotateSelectedOnKey 'ctrl+left', 0, -45, 0
	rotateSelectedOnKey 'ctrl+right', 0, 45, 0
	rotateSelectedOnKey 'alt+left', 0, 0, -45
	rotateSelectedOnKey 'alt+right', 0, 0, 45
	rotateSelectedOnKey 'alt+up', -45, 0, 0
	rotateSelectedOnKey 'alt+down', 45, 0, 0

	# JSON output
	getBaseData = (data) ->
		ip: data.ip
		name: data.name
		group: data.group
		segments: []

	getSegmentData = (data) ->
		x: data.x
		y: data.y
		z: data.z
		rotX: data.rotX
		rotY: data.rotY
		rotZ: data.rotZ
		count: data.count
		type: data.type
		floor: data.floor
		flags: data.flags


	$(document).bind 'keydown', 'ctrl+s', (ev) ->
		ev.preventDefault()
		console.log 'save'

		fixtures = {}

		#$('.fixtureGroup').each (i) ->
		#	fixtures.push $(this).data()

		$('.fixtureGroup').each (i) ->
			data = $(this).data()
			if !fixtures[ data.name ]? then fixtures[ data.name ] = getBaseData data
			fixtures[ data.name ].segments.push getSegmentData data

		fixturesJSON = JSON.stringify {fixtures: fixtures}, null, 2

		blob = new Blob [fixturesJSON], {type: "text/plain;charset=utf-8"}
		saveAs blob, 'fixtures.json'


	valuesJSON = ->
		# TODO ability to send only updated values
		values = {}

		$('.fixture').fixture().each ->
			fixtureOptions = $(this).fixture('optionsObject')
			index = fixtureOptions.index
			name = fixtureOptions.name
			value = fixtureOptions.value
			flags = Array.from fixtureOptions.flags

			if values[ name ] == undefined then values[ name ] = []
			# values[ name ][ index ] = value
			values[ name ].push
				v: value
				f: flags

			# console.log $(this).fixture('optionsObject').flags

		# console.log values

		return JSON.stringify
			values: values
			command: 'values',
			null, 2

	valuesJSON()
	$(document).bind 'keydown', 'ctrl+d', (ev) ->
		ev.preventDefault()

		blob = new Blob [valuesJSON()], {type: "text/plain;charset=utf-8"}
		saveAs blob, 'values.json'

	# WS Communication
	handleMessage = (ev) ->
		console.log 'Handling WS message'
		console.log ev.data
		reply = JSON.parse(ev.data)
		switch reply.command
			when 'pong' then wsPongReceived()
			when 'scenes' then showScenes reply.data


	connectInterval = undefined
	
	initConnectInterval = ->
		if !connectInterval? then connectInterval = window.setInterval initConnection, 2000

	clearConnectInterval = ->
		window.clearInterval connectInterval
		connectInterval = undefined

	pingInterval = undefined
	pingReceived = false

	wsPingHandle = ->
		if pingReceived
			wsPongReceived()
			return true
		else # Ping failed
			window.ws.socket.close()
			clearPingInterval()
			initConnectInterval()
			return false

	clearPingInterval = ->
		console.log 'Ping Timeout Clear'
		window.clearInterval PingInterval
		PingInterval = undefined

	pingSent = false;

	initPingInterval = ->
		console.log 'Ping Interval'
		pingSent = false
		if !pingInterval? then pingInterval = window.setInterval wsPing, 5000

	wsPongReceived = ->
		console.log 'Pong Received'
		pingReceived = true

	wsPing = ->
		if pingSent then if !wsPingHandle() then return

		console.log 'Ping'
		pingReceived = false
		window.ws.send JSON.stringify
			command: 'ping'
		pingSent = true

	initConnection = ->
		window.ws.init
			onmessage: handleMessage
			onopen: ->
				console.log 'connected'
				$('.overlay').hide()
				initPingInterval()
				clearConnectInterval()
				
			onclose: ->
				console.log 'disconnected'
				$('.overlay').show()
				clearPingInterval()
				initConnectInterval()

	sendCommand = ( command, data = {} ) ->
		window.ws.send JSON.stringify
			command: command
			data: data

	saveSceneCommand = ( name ) ->
		sendCommand 'saveScene', name

	deleteSceneCommand = ( name ) ->
		sendCommand 'deleteScene', name

	listScenesCommand = ->
		sendCommand 'listScenes'


	initConnection()


	$(window).on 'dimmer:change', ->
		console.log 'Sending new values'
		window.ws.send valuesJSON()

	#$("#mode").click ->
	#	window.ws.send JSON.stringify
	#		command: 'mode'






