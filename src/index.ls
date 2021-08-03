xfc = (opt = {}) ->
  @ <<< opt{meta-root, font-root}
  @root = if typeof(@root) == \string => document.querySelector(opt.root) else opt.root
  @evt-handler = {}
  @

xfc.prototype = Object.create(Object.prototype) <<< do
  on: (n, cb) -> (if Array.isArray(n) => n else [n]).map (n) ~> @evt-handler.[][n].push cb
  fire: (n, ...v) -> for cb in (@evt-handler[n] or []) => cb.apply @, v
  load: (opt) ->
    family = if typeof(opt) == \number => @meta.family[opt] else opt
    font = family.fonts.0
    if font.xfont => return Promise.resolve that
    s = @meta.index.style[font.s]
    w = @meta.index.weight[font.w]
    path = "#{@font-root}/#{family.n}/#{s}/#{w}#{if font.x => '' else '.ttf'}"
    xfl.load {path, name: family.n}
      .then -> return font.xfont = it

  init: ->
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
      xhr.open \GET, ("#{@meta-root}/meta.json")
      xhr.onerror = -> return rej it
      xhr.send!
    p
      .then ~>
        @cfg = {}
        @view = new ldview do
          root: @root
          handler:
            "cur-subset": ({node}) ~> node.textContent = @cfg.subset or 'All'
            "cur-cat": ({node}) ~> node.textContent = @cfg.category or 'All'
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
            font:
              list: ~> @meta.family
              key: ~> it.n
              action: click: ({node, data, idx}) ~>
                @fire \load.start
                @load data
                  .finally ~> @fire \load.end
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
                node.textContent = ' '
                col = idx % @meta.dim.col
                row = Math.floor(idx / @meta.dim.col)
                w = @meta.dim.width + @meta.dim.padding
                h = @meta.dim.height + @meta.dim.padding
                node.style <<< do
                  width: "#{w}px"
                  height: "#{h}px"
                  backgroundImage: "url(#{@meta-root}/sprite.min.png)"
                  backgroundPosition: "#{-w * col}px #{-h * row}px"
                  margin: \auto


if module? => module.exports = xfc
else if window? => window.xfc = xfc
