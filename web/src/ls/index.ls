fontbase = "https://plotdb.github.io/xl-fontset/alpha"
fontbase = "assets/font/links"
fontinfo = "assets/font/meta"
textarea = document.querySelector \#demo-textarea

modal-chooser = new xfc {
  root: '.ldcv .xfc'
  meta-root: 'assets/fonts/meta'
  font-root: 'assets/fonts/links'
}

modal-chooser.init!
window.ldcv = ldcv = new ldCover root: '.ldcv'
modal-chooser.on \choose, (f) ->
  window.ldcv.toggle false
  textarea.style.fontFamily = f.name
  f.sync textarea.value
