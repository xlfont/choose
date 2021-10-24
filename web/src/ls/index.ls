<-(->it.apply {}) _

textarea = document.querySelector \#demo-textarea
base = "assets/fonts" #"https://xlfont.github.io/sample-set"

i18next.init supportedLng: <[en zh-TW]>, fallbackLng: \zh-TW
  .then ~>

    modal-chooser = new xfc {
      root: '.ldcv .xfc'
      #meta-root: 'assets/fonts/meta'
      #font-root: 'assets/fonts/links'
      meta: "#base/meta"
      links: "#base/links"
      i18n: i18next
    }
    @view = new ldview do
      root: document.body
      action: click: choose: ~> ldcv.toggle!

    modal-chooser.init!
    @ldcv = ldcv = new ldcover root: '.ldcv'
    @ldcv.on \toggle.on, -> modal-chooser.render!
    modal-chooser.on \choose, (f) ~>
      @ldcv.toggle false
      if !f => return
      textarea.style.fontFamily = f.name
      f.sync textarea.value
