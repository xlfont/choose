once = (f, q = []) -> ->
  if q.s == 2 => return Promise.resolve!
  else if q.s == 1 => return new Promise (res, rej) -> q.push {res, rej}
  Promise.resolve(q.s = 1)
    .then -> f!
    .then -> q.s = 2; q.splice 0 .map -> it.res!
    .catch (e) -> q.s = 0; q.splice(0).map(-> it.rej e); Promise.reject(e)

i18n =
  "zh-TW": {
    "Category": "分類"
    "Subset": "子集"
    "Name": "名稱"
    "Use Your Own Font": "上傳"
    "or": "或"
    "Cancel": "取消"
  }

xfc = (opt = {}) ->
  @opt = opt
  @_url = opt{meta,links}
  <[meta links]>.map (n) ~> if !@_url[n] and xfc._url[n] => @_url[n] = xfc._url[n]
  @root = if typeof(opt.root) == \string => document.querySelector(opt.root) else opt.root
  @_init-render = if opt.init-render? => opt.init-render else false
  @evt-handler = {}
  if @root => @ldld = new ldloader container: @root, auto-z: true, class-name: 'ldld full'
  @i18n = opt.i18n or {t: -> it}
  @init = once ~> @_init!
  @

xfc.url = (o = {}) -> return if !arguments.length => (xfc._url or {}) else (xfc.{}_url <<< o)

xfc.prototype = Object.create(Object.prototype) <<< do
  on: (n, cb) -> (if Array.isArray(n) => n else [n]).map (n) ~> @evt-handler.[][n].push cb
  fire: (n, ...v) -> for cb in (@evt-handler[n] or []) => cb.apply @, v
  config: (opt = {}) ->
    <[state upload order]>.for-each ~>
      if opt[it]? => @opt[it] = opt[it]
    <~ @init!then _
    if opt.order and @meta => @meta.family.sort @opt.order
    @render!
  load: (opt) ->
    font = null
    @init!
      .then ~>
        if !opt => return null
        if xfc.{}_custom-font[opt.name] => return xfc._custom-font[opt.name]
        if opt.mod and opt.mod.file and opt.mod.file.blob =>
          return @font-from-file({file: opt.mod.file, name: opt.name})
        family = if typeof(opt) == \number => @meta.family[opt]
        else if typeof(opt) == \string => @meta.family.filter(-> it.n.toLowerCase! == opt.toLowerCase!).0
        # simplified font obj {name, style, weight}
        else if opt.name => @meta.family.filter(->it.n.toLowerCase! == opt.name.toLowerCase!).0
        # font obj itself
        else opt
        if !family => return Promise.reject(new Error! <<< {message: "font not found", id: 404})
        font := family.fonts.0
        if font.xfont => return Promise.resolve that
        s = @meta.index.style[font.s]
        w = @meta.index.weight[font.w]
        path = "#{@_url.links}/#{family.n}/#{s}/#{w}#{if font.x => '' else '.ttf'}"
        (f) <~ xfl.load {path, name: family.n} .then _
        f.{}mod.limited = @_limited {font: opt}
        f
      .then (f) ->
        if font => font.xfont = f
        return f
  _limited: ({font, is-upload}) ->
    if font =>
      n = (font.n or font.name).toLowerCase!
      matched = @meta.family.filter(->it.n.toLowerCase! == n).0
    else matched = false
    fn = if is-upload or !matched => \upload else \state
    limited = !!(if typeof(@opt[fn]) != \function => false
    else @opt[fn]({font, type: \limited}))
    if font => font.{}mod.limited = limited
    return limited

  render: ->
    @ldld.on!
    _ = ~>
      <~ @init!then _
      @view.render!
      @ldld.off!
      @_rendered = true
    # render may be a timing consuming job and thus may block UI.
    if @_rendered => return _!
    return new Promise (res, rej) -> setTimeout (-> _!then -> res it), 50

  font-from-file: ({file, name}) ->
    @ldld.on!
    if !name => name = "custom-" + (parseInt(Math.random! * Date.now!) + Date.now!).toString(36)
    url = URL.createObjectURL(file.blob or file)
    ext = if /(ttf|otf|woff2|woff)$/.exec(file.type or '') => that.1 else \ttf
    xfc.{}_custom-font[name] = font = new xfl.xlfont path: url, name: name, is-xl: false, ext: ext
    xfl.track font
    # keep blob in mod.file for:
    # 1. indicate an uploaded font
    # 2. for data source to save/load
    # we also track common file fields such as lastModified, name, size, type here,
    # yet additional info such as digest or key can be used by caller.
    font.{}mod.file = file{lastModified, name, size, type} <<< {blob: file.blob or file}
    @_limited {font, is-upload: true}
    font.init!
      .finally ~>
        @fire \load.end
        @ldld.off!
      .then ~> @fire \choose, font
      .then -> return font
      .catch ~>
        console.error "[@xlfont/choose] font load failed: ", it
        @fire \load.fail, it
        return null

  _init: ->
    p = new Promise (res, rej) ~>
      xhr = new XMLHttpRequest!
      xhr.addEventListener \readystatechange, ~>
        if xhr.readyState != 4 => return
        if xhr.status != 200 => return rej xhr.responseText
        try
          @meta = JSON.parse(xhr.responseText)
          @meta.family.forEach (n,i) -> n.i = i
          @meta.family = @meta.family.filter(->it.n)
          if @opt.order => @meta.family.sort @opt.order
        catch e
          return rej e
        res!
      xhr.open \GET, ("#{@_url.meta}/meta.json")
      xhr.onerror = -> return rej it
      xhr.send!
    p
      .then ~>
        if !@root => return
        @cfg = {}

        if @i18n.add-resource-bundle
          for k,v of i18n => @i18n.add-resource-bundle k, '@plotdb/choose', v, true, true
          Array.from(@root.querySelectorAll('[t]')).map (n) ~>
            n.textContent = @i18n.t("@plotdb/choose:#{n.textContent}")

        @view = new ldview do
          init-render: @_init-render
          root: @root
          action:
            input: search: ({node}) ~>
              @cfg.keyword = (node.value or '')
              @view.render <[font]>
            click: cancel: ~> @fire \choose, null
            change: upload: ({node}) ~>
              file = if node.files => node.files.0 else null
              node.value = ''
              if !file => return
              @font-from-file {file, name: if file.name => "#{file.name} from Upload" else null}
          init:
            "cur-subset": ({node}) -> if BSN? => new BSN.Dropdown node
            "cur-cat": ({node}) -> if BSN? => new BSN.Dropdown node
          handler:
            "upload-button": ({node}) ~>
              node.classList.toggle \limited, !!@_limited({is-upload: true})
            "cur-subset": ({node}) ~>
              node.textContent = @cfg.subset or 'all'
              node.classList.toggle \active, !!(@cfg.subset and @cfg.subset != 'all')
            "cur-cat": ({node}) ~>
              node.textContent = @cfg.category or 'all'
              node.classList.toggle \active, !!(@cfg.category and @cfg.category != 'all')
            category:
              list: ~> <[all]> ++ @meta.index.category
              action: click: ({node, data}) ~>
                @cfg.category = data
                @view.render <[font cur-cat category]>
              handler: ({node, data}) ~>
                node.textContent = data
                node.classList.toggle \active, (@cfg.category == data or (!@cfg.category and data == \all))
            subset:
              list: ~> <[all]> ++ @meta.index.subset
              action: click: ({node, data}) ~>
                @cfg.subset = data
                @view.render <[font cur-subset subset]>
              handler: ({node, data}) ~>
                node.textContent = data
                node.classList.toggle \active, (@cfg.subset == data or (!@cfg.subset and data == \all))
            "font-list": ({node}) ~>
              w = @meta.dim.width
              node.style.gridTemplateColumns = "repeat(auto-fill,#{w}px)"
            font:
              list: ~> @meta.family
              host: if vscroll? => vscroll.fixed
              key: ~> it.n
              action: click: ({node, data}) ~>
                @ldld.on!
                @fire \load.start
                @load data
                  .finally ~>
                    @fire \load.end
                    @ldld.off!
                  .then ~> @fire \choose, it
                  .catch ~>
                    console.error "[@xlfont/choose] font load failed: ", it
                    @fire \load.fail, it
              handler: ({node, data}) ~>
                [k,c,s,idx] = [@cfg.keyword, @cfg.category, @cfg.subset, @meta.index]
                node.classList.toggle \limited, @_limited {font: data}
                node.classList.toggle \d-none, (
                  !data.n or
                  (k and !~(('' + data.n + data.d).toLowerCase!).indexOf(k.toLowerCase!)) or
                  !(!c or c == \all or (idx.category.indexOf(c) == data.c)) or
                  !(!s or s == \all or (idx.subset.indexOf(s) in data.s))
                )
              init: ({node, data}) ~>
                idx = data.i
                col = idx % @meta.dim.col
                row = Math.floor(idx / @meta.dim.col)
                p = @meta.dim.padding
                w = @meta.dim.width
                h = @meta.dim.height
                n = node.querySelector('[ld=name]')
                b = node.querySelector('[ld=preview]')
                node.style <<< {}
                b.style <<< do
                  width: "#{w}px"
                  height: "#{h}px"
                  backgroundImage: "url(#{@_url.meta}/sprite.min.png)"
                  backgroundPosition: "#{-(w + p) * col}px #{-(h + p) * row}px"
                n.textContent = data.n

if module? => module.exports = xfc
else if window? => window.xfc = xfc
