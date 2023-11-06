<-(->it.apply {}) _

textarea = document.querySelector \#demo-textarea
base = "assets/fonts" #"https://xlfont.github.io/sample-set"
base = "https://xlfont.maketext.io"

i18next.init supportedLng: <[en zh-TW]>, fallbackLng: \zh-TW
  .then ~>

    list = ["Bevan", "ABeeZee", "Abel", "Abhaya Libre", "Abril Fatface", "Abyssinica SIL", "Aclonica",
    "Acme", "Actor", "Adamina", "Advent Pro", "Aguafina Script", "Akronim", "Aladin"]
    modal-chooser = new xfc {
      root: '.ldcv .xfc'
      #meta-root: 'assets/fonts/meta'
      #font-root: 'assets/fonts/links'
      meta: "#base/meta"
      links: "#base/links"
      i18n: i18next
      upload: -> return true
      state: ({font, idx, type}) ->
        if type == \limited => return if font.n in list => false else true
      order: (a, b) ->
        [an, bn] = [a.n.toLowerCase!, b.n.toLowerCase!]
        [pa, pb] = [(a.n in list), (b.n in list)]
        if pa xor pb => return if pa => -1 else 1
        if an > bn => 1 else if an < bn => -1 else 0
    }
    @view = new ldview do
      root: document.body
      action: click: choose: ~> ldcv.toggle!

    modal-chooser.init!
    @ldcv = ldcv = new ldcover root: '.ldcv'
    @ldcv.on \toggle.on, -> modal-chooser.render!
    modal-chooser.on \choose, (f) ~>
      console.log "chosen font: ", f
      @ldcv.toggle false
      if !f => return
      textarea.style.fontFamily = f.name
      f.sync textarea.value
