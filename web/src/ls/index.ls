textarea = document.querySelector \#demo-textarea
base = "https://xlfont.github.io/sample-set"

i18next.init supportedLng: <[en zh-TW]>, fallbackLng: \zh-TW
  .then ->

    modal-chooser = new xfc {
      root: '.ldcv .xfc'
      #meta-root: 'assets/fonts/meta'
      #font-root: 'assets/fonts/links'
      meta-root: "#base/meta"
      font-root: "#base/links"
      i18n: i18next
    }

    modal-chooser.init!
    window.ldcv = ldcv = new ldCover root: '.ldcv'
    modal-chooser.on \choose, (f) ->
      window.ldcv.toggle false
      if !f => return
      textarea.style.fontFamily = f.name
      f.sync textarea.value
