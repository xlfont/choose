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
    "Upload": "上傳"
    "or": "或"
    "Cancel": "取消"
  }

xfc = (opt = {}) ->
  @_url = opt{meta,links}
  @root = if typeof(opt.root) == \string => document.querySelector(opt.root) else opt.root
  @_init-render = if opt.init-render? => opt.init-render else false
  @evt-handler = {}
  if @root => @ldld = new ldloader container: @root, auto-z: true, class-name: 'ldld full'
  @i18n = opt.i18n or {t: -> it}
  @init = once ~> @_init!
  @

xfc.prototype = Object.create(Object.prototype) <<< do
  on: (n, cb) -> (if Array.isArray(n) => n else [n]).map (n) ~> @evt-handler.[][n].push cb
  fire: (n, ...v) -> for cb in (@evt-handler[n] or []) => cb.apply @, v
  load: (opt) ->
    @init!
      .then ~>
        family = if typeof(opt) == \number => @meta.family[opt]
        else if typeof(opt) == \string => @meta.family.filter(-> it.n.toLowerCase! == opt.toLowerCase!).0
        # simplified font obj {name, style, weight}
        else if opt.name => @meta.family.filter(->it.n.toLowerCase! == opt.name.toLowerCase!).0
        # font obj itself
        else opt
        if !family => return Promise.reject(new Error! <<< {message: "font not found", id: 404})
        font = family.fonts.0
        if font.xfont => return Promise.resolve that
        s = @meta.index.style[font.s]
        w = @meta.index.weight[font.w]
        path = "#{@_url.links}/#{family.n}/#{s}/#{w}#{if font.x => '' else '.ttf'}"
        xfl.load {path, name: family.n}
          .then -> return font.xfont = it

  render: ->
    @ldld.on!
    _ = ~>
      @view.render!
      @ldld.off!
      @_rendered = true
    # render may be a timing consuming job and thus may block UI.
    if @_rendered => _!
    else setTimeout (-> _!), 50
  _init: ->
    p = new Promise (res, rej) ~>
      xhr = new XMLHttpRequest!
      xhr.addEventListener \readystatechange, ~>
        if xhr.readyState != 4 => return
        if xhr.status != 200 => return rej xhr.responseText
        try
          @meta = JSON.parse(xhr.responseText)
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
          action: click:
            cancel: ~> @fire \choose, null
          handler:
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
              action: click: ({node, data, idx}) ~>
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
              handler: ({node, data, idx}) ~>
                [c,s,idx] = [@cfg.category, @cfg.subset, @meta.index]
                node.classList.toggle \d-none, (
                  !(!c or c == \all or (idx.category.indexOf(c) == data.c)) or
                  !(!s or s == \all or (idx.subset.indexOf(s) in data.s))
                )
              init: ({node, data, idx}) ~>
                col = idx % @meta.dim.col
                row = Math.floor(idx / @meta.dim.col)
                p = @meta.dim.padding
                w = @meta.dim.width
                h = @meta.dim.height
                n = node.querySelector('[ld=name]')
                node.style <<< do
                  width: "#{w}px"
                  height: "#{h}px"
                  backgroundImage: "url(#{@_url.meta}/sprite.min.png)"
                  backgroundPosition: "#{-(w + p) * col}px #{-(h + p) * row}px"
                n.textContent = data.n

if module? => module.exports = xfc
else if window? => window.xfc = xfc
