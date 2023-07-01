app = null
game = null
stage = null
gems = [...Array 8].map (v) => [...Array 8]
slot = null
blocks = []
maskBlock = null
isMobile = "ontouchstart" of window

preload = ->
	stage = @
	for k, v of fn
		if typeof v is "function"
			fn[k] = v.bind @
	fn.setGameSize()
	app.hasGame = yes
	@load.crossOrigin = yes
	@load.path = "assets/"
	@load.image "slot"
	@load.image "gem"
	@load.image "block"
	@load.audio "match", "match.mp3"
	@load.audio "put", "put.mp3"
	@load.audio "break", "break.mp3"
	return

create = ->
	app.state = "loaded"
	# play.call stage unless isMobile
	return

fn =
	colors: [0xdc3545, 0xfd7e14, 0xffc107, 0x28a745, 0x20c997, 0x007bff, 0xa049f4, 0xe83e8c]
	mapBlocks: [
		# 0 0 0
		[[-1, 0], [0, 0], [1, 0]]
		# 0 0
		# 0 0
		[[0, 0], [0, 1], [1, 0], [1, 1]]
		# 0 0
		[[0, 0], [1, 0]]
		# 0
		# 0
		[[0, 0], [0, 1]]
		# 0
		[[0, 0]]
		# 0 0
		# 0
		[[0, 1], [0, 0], [1, 0]]
		# 0 0 0 0
		[[-1, 0], [0, 0], [1, 0], [2, 0]]
		# 0
		# 0
		# 0
		# 0
		[[0, -1], [0, 0], [0, 1], [0, 2]]
		# 0
		# 0 0
		[[0, 0], [0, 1], [1, 1]]
		# 0
		# 0 0 0
		[[-1, 0], [-1, 1], [0, 1], [1, 1]]
		#   0
		# 0 0 0
		[[0, 0], [-1, 1], [0, 1], [1, 1]]
		#   0 0
		# 0 0
		[[-1, 1], [0, 1], [0, 0], [1, 0]]
		# 0 0 0 0 0
		[[-2, 0], [-1, 0], [0, 0], [1, 0], [2, 0]]
		# 0
		# 0
		# 0
		# 0
		# 0
		[[0, -2], [0, -1], [0, 0], [0, 1], [0, 2]]
		# 0 0 0
		#     0
		#     0
		[[-1, -1], [0, -1], [1, -1], [1, 0], [1, 1]]
		# 0 0 0
		# 0 0 0
		# 0 0 0
		[[-1, -1], [-1, 0], [-1, 1], [0, -1], [0, 0], [0, 1], [1, -1], [1, 0], [1, 1]]
	]
	makeGem: (x, y, tint, offsetX = 0, offsetY = 0) ->
		gem = @make.sprite x * 40 + offsetX, y * 40 + offsetY, "gem"
		gem.anchor.set .5
		gem.tint = tint
		gem
	addGem: (...args) ->
		@world.add fn.makeGem ...args
	addBlock: (i) ->
		block = @add.sprite 60 + i * 120, 520, "block"
		block.anchor.set .5
		block.scale.set .5
		block.gems = @add.group block
		block.mapBlock = @rnd.weightedPick fn.mapBlocks
		block.tintBlock = @rnd.pick fn.colors
		block.gems.addMultiple block.mapBlock.map (val) =>
			fn.addGem val[0], val[1], block.tintBlock
		@physics.arcade.enable block
		block.inputEnabled = yes
		block.input.enableDrag no, yes
		block.events.onDragStart.add (spr) =>
			spr.scale.set 1
			spr.gems.alpha = .8
			maskBlock.gems.addMultiple spr.gems.children.map (gem) =>
				fn.makeGem 0, 0, gem.tint, gem.x, gem.y
			return
		block.events.onDragUpdate.add (spr, pt, dragX, dragY) =>
			{x, y} = spr.gems.worldPosition
			x = @math.snapToCeil(x - slot.x, 40) / 40 - 1
			y = @math.snapToCeil(y - slot.y, 40) / 40 - 1
			dragY -= 160
			spr.y = dragY
			if fn.canPutBlock block, x, y
				maskBlock.visible = yes
				maskX = x * 40 + 40
				maskY = y * 40 + 120
				maskBlock.position.set maskX, maskY
			else
				maskBlock.visible = no
			return
		block.events.onDragStop.add (spr, pt) =>
			{x, y} = spr.gems.worldPosition
			x = @math.snapToCeil(x - slot.x, 40) / 40 - 1
			y = @math.snapToCeil(y - slot.y, 40) / 40 - 1
			if fn.canPutBlock block, x, y
				fn.putBlockToGems block, x, y
			spr.x = 60 + i * 120
			spr.y = 520
			spr.scale.set .5
			spr.gems.alpha = 1
			maskBlock.visible = no
			maskBlock.gems.removeAll()
			return
		block
	canPutBlock: (block, x0, y0) ->
		for val from block.mapBlock
			x = x0 + val[0]
			y = y0 + val[1]
			if x < 0 or x > 7 or y < 0 or y > 7 or gems[y][x]
				return no
		yes
	putBlockToGems: (block, x0, y0) ->
		for val from block.mapBlock
			x = x0 + val[0]
			y = y0 + val[1]
			gems[y][x] = fn.addGem x, y, block.tintBlock, slot.x + 20, slot.y + 20
		app.addScore block.gems.children.length
		blocks.splice blocks.indexOf(block), 1
		block.destroy()
		@sound.play "put"
		fn.matchGems()
		return
	matchGems: ->
		matches = []
		for row, y in gems
			if row.every (val) => val
				matches = matches.concat row.map (gem, x) => {x, y}
		for x in [0...8]
			tmpMathches = []
			for y in [0...8]
				if gems[y][x]
					tmpMathches.push {x, y}
				else
					tmpMathches = null
					break
			if tmpMathches
				for tmpMathch from tmpMathches
					unless matches.some (val) => val.x is tmpMathch.x and val.y is tmpMathch.y
						matches.push tmpMathch
		if matches.length
			for match from matches
				gem = gems[match.y][match.x]
				fn.emitGem gem
				gem.destroy()
				gems[match.y][match.x] = null
			app.addScore matches.length
			@sound.play "match"
		fn.disableBlocks()
		matches.length
	emitGem: (gem) ->
		emitter = @add.emitter gem.x, gem.y, 1
		emitter.makeParticles gem.key
		emitter.gravity = 800
		emitter.forEach (particle) =>
			particle.tint = gem.tint
			return
		emitter.setAlpha 1, 0, 800
		emitter.setScale 1, .3, 1, .3, 800
		emitter.start yes, 800, null, 1
		@time.events.add 800, emitter.destroy, emitter
	disableBlocks: ->
		if blocks.length
			isLost = yes
			for block from blocks
				do =>
					for y in [0...8]
						for x in [0...8]
							if fn.canPutBlock block, x, y
								block.alpha = 1
								block.input.enabled = yes
								isLost = no
								return
							else
								block.alpha = .3
								block.input.enabled = no
					return
			if isLost
				fn.lost()
		return
	lost: ->
		app.canRestart = no
		tween = @add.tween n: 0
			.to n: 64, 3200
		tween.onUpdateCallback (tween) =>
			{n} = tween.target
			x = Math.round n % 8
			y = n // 8
			if gem = gems[y][x]
				gem.tint = 0x333333
				fn.emitGem gem
				gem.destroy()
				gems[y][x] = null
				@sound.play "break"
			return
		tween.onComplete.add =>
			app.canRestart = yes
			fn.restart()
			return
		tween.start()
		return
	restart: ->
		if app.canRestart
			for y in [0...8]
				for x in [0...8]
					if gem = gems[y][x]
						gem.destroy()
						gems[y][x] = null
			for block from blocks
				block.destroy()
			blocks = []
			app.score = 0
			app.score2 = 0
		return
	setGameSize: ->
		app.width = Phaser.Math.clamp innerWidth, 0, 360
		app.height = Phaser.Math.clamp innerHeight, 0, 640
		@scale.setGameSize app.width, app.height
		return

play = ->
	slot = @add.tileSprite 20, 100, 8 * 40, 8 * 40, "slot"
	maskBlock = @add.sprite 0, 0, "block"
	maskBlock.gems = @add.group maskBlock
	maskBlock.anchor.set .5
	maskBlock.alpha = .5
	maskBlock.visible = no
	app.state = "play"
	return

update = ->
	if app.state is "play"
		unless blocks.length
			for i in [0...3]
				blocks.push fn.addBlock i
			fn.disableBlocks()
		if app.score2 < app.score
			app.score2++
		if app.highScore2 < app.highScore
			app.highScore2++
	return

mounted = ->
	game = new Phaser.Game
		width: 360
		height: 640
		parent: "game"
		antialias: no
		crisp: yes
		roundPixels: yes
		transparent: yes
		state:
			preload: preload
			create: create
			update: update
	@isFullscreen = not isMobile
	document.onfullscreenchange = =>
		@isFullscreen = document.fullscreenElement
		return
	window.onresize = =>
		fn.setGameSize()
		return
	return

app = new Vue
	el: "#app"

	data: ->
		highScore = +localStorage.highScore or 0
		state: "preload"
		hasGame: no
		score: 0
		score2: 0
		highScore: highScore
		highScore2: highScore
		isFullscreen: no
		width: 0
		height: 0
		canRestart: yes
		fn: fn

	computed:
		styleUIBox: ->
			width: @width + "px"
			height: @height + "px"

	methods:
		play: ->
			play.call stage
			return

		addScore: (amount) ->
			@score += amount
			if @score > @highScore
				@highScore = @score
				localStorage.highScore = @highScore
			return

		fullscreen: ->
			document.body.requestFullscreen()
			return

	mounted: ->
		mounted.call @
		return
