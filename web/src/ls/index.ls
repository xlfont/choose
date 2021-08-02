fontbase = "https://plotdb.github.io/xl-fontset/alpha"
fontbase = "assets/font/links"
fontinfo = "assets/font/meta"
textarea = document.querySelector \#demo-textarea

modal-chooser = new xfc {
  root: '.ldcv .xfc', meta-url: "#fontinfo/meta.json", base: fontbase
  meta-root: 'assets/fonts/meta'
  font-root: 'assets/fonts/links'
}
modal-chooser.init!
modal-chooser.on \choose, -> ldcv.toggle false

window.ldcv = ldcv = new ldCover root: '.ldcv'

/*
dropdown-chooser = new xfc do
  root: '#demo-dropdown', meta-url: "#fontinfo/meta.json", itemClass: \dropdown-item, type: \list, base: fontbase
dropdown-chooser.init!
dropdown-chooser.on \choose, (font) ->
list-chooser = new xfc do
  root: '#demo-list-group', meta-url: "#fontinfo/meta.json", itemClass: \list-group-item, type: \list, base: fontbase
list-chooser.init!
[modal-chooser, list-chooser, dropdown-chooser].map ->
  it.on \choose, (font) ->
    <- font.sync textarea.value, _
    textarea.style.fontFamily = font.name

xfl.load "#fontbase/CroissantOne-Regular.ttf"
xfl.load "#fontbase/Gafata-Regular.ttf"
*/
