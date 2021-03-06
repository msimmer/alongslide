#
# alongslide.cofee: Central init, pull in submodules.
#
# Copyright 2013 Canopy Canopy Canopy, Inc.
# Authors Adam Florin & Anthony Tran
#
class Alongslide

  panels     : {}
  sections   : {}

  parser     : null
  layout     : null
  scrolling  : null
  state      : null

  constructor: (options= {}) ->
    @source       = $(options.source)  ? $('#content .raw')
    @frames       = $(options.to)      ? $('#frames')
    @regionCls    = options.regionCls  ? 'column'
    @marginTop    = options.marginTop  ? 0
    @panelNames   = {}

    RegionFlow::init()

    # parse
    @parser = new @Parser source: @source
    {@flowNames, @backgrounds, @panels, @footnotes, @sourceLength} = @parser.parse()

    # init layout
    @layout = new @Layout
      sourceLength:    @sourceLength
      frames:          @frames
      flowNames:       @flowNames
      backgrounds:     @backgrounds
      panels:          @panels
      regionCls:       @regionCls
      panelNames:      @panelNames

    # init scrolling
    @scrolling = new @Scrolling
      frames:          @frames

    # init broswer history
    @state = new @State
      panelNames: @panelNames


  # Render flowing layout and scroll behavior.
  #
  # Force use of CSS Regions polyfill. (Don't trust native browser support
  # while W3C draft is under active development.)
  #
  # @param frameAspect - bounding box computed by FixedAspect
  # @param postRenderCallback - to be called when layout returns
  #
  render: (postRenderCallback) ->
    frameAspect = FixedAspect.prototype.fitFrame(@layout.FRAME_WIDTH, @marginTop)
    @layout.render (lastFramePosition) =>

      @lastFramePosition = lastFramePosition

      @refresh(frameAspect)
      @applyFootnotes()
      @applyAnchorScrolling()

      # Emit notification that layout is complete.
      $(document).triggerHandler 'alongslide.ready', @frames

      @hashToPosition()
      FixedAspect.prototype.fitPanels(frameAspect)
      postRenderCallback()

  # Refresh Skrollr only on resize events, as it's fast.
  #
  refresh: ->
    frameAspect = FixedAspect.prototype.fitFrame(@layout.FRAME_WIDTH, @marginTop)
    @scrolling.render(frameAspect, @lastFramePosition)
    FixedAspect.prototype.fitPanels(frameAspect)

  hashToPosition: ->
    hash = window.location.hash
    if hash.length > 0
      @goToPanel(hash.substr(1))
    else
      @goToPanel('titlesplash')


  # Create footnotes
  #
  # Sanitize Markdown generated HTML
  applyFootnotes: ->
    # For each footnote in the article
    @frames.find('.als-fn-ref').each (i, el) =>
      # Reference the footnote
      $el = $(el)
      # Find the footnote text
      $footnote = @footnotes.find($el.data('anchor'))

      # Append the footnote text element to the column
      $column = $el.parents('.column')
      $column.append($footnote)

      # place footnote, prevent placing offscreen
      bottom = $column.height() + $column.offset().top
      if ($el.offset().top + $footnote.height()) > bottom
        $footnote.css('bottom', 0)
      else
        $footnote.css('top', $el.parent().position().top )

      $el.on "mouseenter click", (e) ->
        e.preventDefault()
        e.stopImmediatePropagation()
        $footnote.fadeIn(150)
        false

      $footnote.on "mouseleave click", (e) ->
        setTimeout ( ()-> $footnote.fadeOut(150) ), 100
        false

  applyAnchorScrolling: ->
    self = @
    @frames.find('a[href*=#]:not([href=#])').on('click', (e) ->
      self.goToPanel(@hash.substr(1))
    )

  goToPanel: (alsId) =>
    $target = $('#frames').find('[data-alongslide-id=' + alsId + ']')
    targetPos = $target.data('als-in-position')
    @scrolling.scrollToPosition(targetPos)


# Make global
#
window.Alongslide = Alongslide
