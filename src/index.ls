xfc = (opt = {}) ->
  @ <<< opt{meta-root, font-root}
  @root = if typeof(@root) == \string => document.querySelector(opt.root) else opt.root
  @evt-handler = {}
  @

xfc.prototype = Object.create(Object.prototype) <<< do
  on: (n, cb) -> (if Array.isArray(n) => n else [n]).map (n) ~> @evt-handler.[][n].push cb
  fire: (n, ...v) -> for cb in (@evt-handler[n] or []) => cb.apply @, v
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
        console.log @meta
        @view = new ldview do
          root: @root
          handler:
            category:
              list: ~> @meta.index.category
              handler: ({node, data}) ->
                node.textContent = data
            subset:
              list: ~> @meta.index.subsets
              handler: ({node, data}) ->
                node.textContent = data
            font:
              list: ~> @meta.family
              key: ~> it.name
              handler: ({node, data, idx}) ~>
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
                  margin: \.25em


if module? => module.exports = xfc
else if window? => window.xfc = xfc
