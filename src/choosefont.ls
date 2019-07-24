ChooseFont = (opt = {}) ->
  @ <<< opt{root, meta-url, type, wrapper, itemClass, cols, base, disable-filter, default-filter}
  @opt = opt
  if !@disable-filter => @disable-filter = -> false
  @root = if typeof(@root) == \string => document.querySelector(@root) else @root
  @root.classList.add \choosefont
  @node = @root.querySelector '.choosefont-content'
  @input = @root.querySelector('input')
  if !@cols => @cols = 4
  if !@node =>
    @node = document.createElement("div")
    @node.classList.add \choosefont-content
    @root.appendChild @node
  @root.querySelector '.btn-group'
  @filter.value = {name: '', category: ''}
  return @

ChooseFont.variants = <[Italic Regular Bold ExtraBold Medium SemiBold ExtraLight Light Thin Black BlackItalic BoldItalic ExtraBoldItalic MediumItalic LightItalic ThinItalic SemiBoldItalic ExtraLightItalic DemiBold Heavy UltraLight]>

ChooseFont.prototype = Object.create(Object.prototype) <<< do
  apply-filters: (o) ->
    if o? => <[disableFilter defaultFilter]>.map ~> if o[it] => @[it] = o[it]
    if @disable-filter and @meta =>
      for idx from 0 til @meta.fonts.length =>
        f = @meta.fonts[idx]
        disabled = @disable-filter(f,idx) # and !(@default-filter or (->true))(d,i)
        f[if @opt.limit-hard => \disabled else \limited] = disabled
        if f.limited => f.html = f.html.replace /disabled|enabled/, \limited
        else if !f.disabled => f.html = f.html.replace /disabled|limited/, \enabled
      @render!
    #TODO support default-filter

  wrap: (font, idx) ->
    if @wrapper => return @wrapper font, idx
    if !@type or @type == \grid or @type == \list =>
      c = (@itemClass or '')
      font.html = """
        <div class="item #c disabled" data-idx="#idx"><div class="inner">
          <div class="img" style="background-position:#{font.x}px #{font.y}px"></div>
          <span>#{font.name}</span>
        </div></div>
      """
  filter: (f) ->
    {name, category} = f or @filter.value or {}
    name = (name or '').toLowerCase!
    list = @fonts.list.filter ->
      (!name or ~it.name.toLowerCase!indexOf(name)) and
      (!category or (it.category or []).filter(->~(it or '').indexOf(category)).length)
    @render list

  clusterize: (html) ->
    if !(Clusterize?) =>
      @node.innerHTML = html.join('')
      return
    if !@cluster =>
      @node.classList.add \clusterize-scroll
      @node.innerHTML = '<div class="clusterize-content"></div>'
      @cluster = new Clusterize do
        html: []
        scrollElem: @node
        contentElem: @node.querySelector('.clusterize-content')
        rows_in_block: 50
        no_data_text: 'found nothing ...'
    @cluster.update html

  find: (names = []) ->
    names
      .map ->
        ret = it.split(\-)
        [name,family] = if ret[* - 1] in ChooseFont.variants =>
          [ret.slice(0, ret.length - 1).join('-'), ret[* - 1]]
        else [ret.join('-'), null]
        return [name, family]
      .map ~> [@fonts.hash[it.0], it.1]
      .filter -> it.0

  load: (font) -> new Promise (res, rej) ~>
    family = if !font.family.length => ""
    else "-" + (if font.family.indexOf(\Regular) => \Regular else font.family.0)
    path = "#{@base}/#{font.name}#family#{if font.isSet => '/' else '.ttf'}"
    if xfl? =>
      @fire \loading.font, font
      # give it a little break so caller might be able to handle 'loading.font' better
      setTimeout (~> xfl.load path, (~>
        if font.limited => it.limited = true
        @fire(\choose, it, {limited: font.limited}); res it
      )), 10
    else
      @fire \choose.map, font, {limited: font.limited}
      res font

  prepare: ->
    @root.addEventListener \click, (e) ~>
      tgt = e.target
      idx = tgt.getAttribute \data-idx
      font = @meta.fonts[idx]
      if font => return if font.disabled => null else @load font
      category = tgt.getAttribute \data-category
      if !(category?) => return
      f = @filter.value or {}
      Array.from(@root.querySelectorAll('*[data-category]')).map -> it.classList.remove \active
      c = (category or '').replace(' ', '_').toUpperCase!
      if f.category == c or c == \ALL =>
        f.category = null
      else
        tgt.classList.add \active
        f.category = c
      @root.querySelector('*[data-category-holder]').innerText = category or 'Family...'
      @filter f
    if @input => @input.addEventListener \keyup, (e) ~>
      @filter.value.name = e.target.value
      @filter!
      return @

    @fonts = list: @meta.fonts, hash: {}
    if @disable-filter => @meta.fonts.map (d,i) ~>
      d[if @opt.limit-hard => \disabled else \limited] = @disable-filter(d,i)
    if @default-filter => @fonts.list = @fonts.list.filter @default-filter
    for idx from 0 til @meta.fonts.length =>
      font = @meta.fonts[idx]
      @fonts.hash[font.name] = font <<< do
        x: -(idx % @meta.dim.col) * @meta.dim.width
        y: -Math.floor(idx / @meta.dim.col) * @meta.dim.height
      @wrap font, idx
    @apply-filters!
    @render!

  render: (list) ->
    if !@node or !@fonts => return
    if !list => list = @fonts.list
    if @type == \grid or !@type =>
      [html, line] = [[], []]
      for idx from 0 til list.length =>
        line.push list[idx].html
        if line.length >= @cols =>
          html.push line
          line = []
      if line.length => html.push line
      @clusterize html.map(-> """<div class="line"><div class="inner">#{it.join('')}</div></div>""")

    else if @type == \list =>
      @clusterize list.map(-> it.html)

  on: (name, cb) -> @{}handler[][name].push cb
  fire: (name, payload) -> @{}handler[][name].map -> it payload

  init: (cb) -> new Promise (res, rej) ~>
    if !cb => cb = (->)
    if !(@meta-url) => return cb null
    xhr = new XMLHttpRequest!
    xhr.addEventListener \readystatechange, ~>
      if xhr.readyState != 4 => return
      if xhr.status != 200 => return rej xhr.responseText
      try
        @meta = JSON.parse(xhr.responseText)
      catch e
        return rej e
      @prepare!
      if cb => cb!
      res!
    #TODO cache this?
    xhr.open \GET, @meta-url
    xhr.onerror = -> return rej it
    xhr.send!
