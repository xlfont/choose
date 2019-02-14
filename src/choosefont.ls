ChooseFont = (opt = {}) ->
  @ <<< opt{root, meta-url, type, wrapper, itemClass, cols, base}
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

ChooseFont.prototype = Object.create(Object.prototype) <<< do
  wrap: (font, idx) ->
    if @wrapper => return @wrapper font, idx
    if !@type or @type == \grid or @type == \list =>
      font.html = """
        <div class="item #{@itemClass or ''}" data-idx="#idx"><div class="inner">
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
      .map -> it.split(\-).filter(->it)
      .map ~> [@fonts.hash[it.0], it.1]
      .filter -> it.0

  load: (font) -> new Promise (res, rej) ~>
    family = if !font.family.length => ""
    else "-" + (if font.family.indexOf(\Regular) => \Regular else font.family.0)
    path = "#{@base}/#{font.name}#family#{if font.isSet => '/' else '.ttf'}"
    if xfl? => xfl.load path, ~>
      @fire \choose, it
      res it
    else 
      @fire \choose.map, font
      res font

  prepare: ->
    @root.addEventListener \click, (e) ~>
      tgt = e.target
      idx = tgt.getAttribute \data-idx
      font = @fonts.list[idx]
      if font => return @load font
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
    for idx from 0 til @meta.fonts.length =>
      font = @meta.fonts[idx]
      @fonts.hash[font.name] = font <<< do
        x: -(idx % @meta.dim.col) * @meta.dim.width
        y: -Math.floor(idx / @meta.dim.col) * @meta.dim.height
      @wrap font, idx
    @render!

  render: (list) ->
    if !@node => return
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
