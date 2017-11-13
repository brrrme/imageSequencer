class exports.ImageSequenceLayer extends Layer

	constructor:(options) ->
		# Check and make sure we have the properties we need
		return @errorForMissingProperties() if @isMissingProperties(options)

		# ImageSequenceLayer defaults
		options.clip ?= true
		options.backgroundColor ?= "transparent"
		super options

		#required reelOptions: totalFrameCount, firstFrameURI
		options.reelOptions.frameWidth ?= @width
		options.reelOptions.frameHeight ?= @height
		options.reelOptions.fps ?= 60
		options.reelOptions.autoloop ?= false
		options.reelOptions.autoplay ?= false
		@reelOptions = options.reelOptions

		@playing = false

		@activeFrame = 1

		@reel = loadFrames(@reelOptions)
		@reel.parent = @

		@setupReel()

		if @reelOptions.autoplay then @play()

		# Create Click Event for Frame to DEBUG
		#@setupClickForFrameOutline()

	# Setup Methods
	loadFrames = (reelOptions) ->
		reel = new Layer
			width: reelOptions.frameWidth * reelOptions.totalFrameCount
			height: reelOptions.frameHeight
			backgroundColor: "transparent"
			clip: true

		# split URI string by '.' resulting in array of chunks
		URIChunks  = _.split(reelOptions.firstFrameURI, '.')
		#get the last chunk which is the file extension name e.g. PNG
		fExtension = _.last(URIChunks)
		# the second last chunk (right before the extension will contain the file name index,
		# so we extract the digits from that string, and select the last one )
		fNameDigitsStr = _.last(URIChunks[URIChunks.length - 2].match(/([\d])+/g))
		# combine URIchunks from first to the one containing the file name index
		# then join those elements into a string with '.' in between
		# then the slice out the part with the digits string e.g. "00000"
		fNameHeadStr = _.join(_.slice(URIChunks, 0, URIChunks.length-1), ".")
			.slice(0, -fNameDigitsStr.length)
		#print fNameHeadStr, fNameDigitsStr

		# stitch frames onto reel layer, so that all frame layers are sequentially placed from left to right
		for i in [ 0 ... reelOptions.totalFrameCount ]
			imageURI = fNameHeadStr + fNameDigitsStr + "." + fExtension

			f = new Layer
				parent: reel
				width: reelOptions.frameWidth
				height: reelOptions.frameHeight
				x: i * reelOptions.frameWidth
				image: imageURI
				backgroundColor: "transparent"

			fNameDigitsStr = plusOneToFileIndex(fNameDigitsStr)

		return reel

	setupReel: () =>
		@sequence = new Animation @reel,
			x: @activeFramePositionX()
			options:
				instant: true
				delay: 1 / @reelOptions.fps

		@sequence.on Events.AnimationStart, (animation, layer) =>
			# Check we don't play when we should be stopped
			animation.stop() unless @isPlaying

		@sequence.on Events.AnimationEnd, (animation, layer) =>
			# Set the activeStep on the sxte object
			@activeFrame++

			if @activeFrame >= @reelOptions.totalFrameCount
				@activeFrame = 1
				# Check if we should only play once
				if !@reelOptions.autoloop
					@shouldOnlyPlayOnce = false
					return

			# Update the animation with a new x position
			@sequence.properties.x = @activeFramePositionX()
			# Only play next frame if we aren't stopped
			@sequence.start() if @isPlaying


	# Helper Methods
	plusOneToFileIndex = (intStr) ->
		index = _.parseInt(intStr) #get the int value
		# return string with leading zeros and int value added by one
		return _.padStart(_.toString(++index), intStr.length, '0')

	activeFramePositionX: =>
		return -( @reelOptions.frameWidth * @activeFrame )

	# interface for users
	play: =>
		@isPlaying = true
		@sequence.start()

	playOnce: =>
		@isPlaying = true
		@shouldOnlyPlayOnce = true
		@sequence.start()

	pause: =>
		@isPlaying = false
		@sequence.stop()

	stop: =>
		@sequence.stop()

	# Error & Debug methods ######################################################

	setupClickForFrameOutline: =>
		@.on Events.Click, -> @.clip = !@.clip
		@.style = "outline": "1px solid red"

	isMissingProperties: (options) =>
		return (
			!options? or
			!options.width? or
			!options.height? or
			!options.reelOptions.totalFrameCount? or
			!options.reelOptions.firstFrameURI?
		)

	errorForMissingProperties: =>
#		error null
		console.error "You must pass the properties width, height, steps & stepsImage to the new SpriteAnimation."
		return
