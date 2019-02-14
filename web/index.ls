<- $ document .ready

fontbase = "https://plotdb.github.io/xl-fontset/alpha"
fontinfo = "assets/fontinfo"
textarea = document.querySelector \#demo-textarea

modal-chooser = new ChooseFont {node: '#demo-modal .choosefont', meta-url: "#fontinfo/meta.json", base: fontbase}
modal-chooser.init!
modal-chooser.on \choose, -> $('#demo-modal').modal('hide')

dropdown-chooser = new ChooseFont do
  node: '#demo-dropdown', meta-url: "#fontinfo/meta.json", itemClass: \dropdown-item, type: \list, base: fontbase
dropdown-chooser.init!
dropdown-chooser.on \choose, (font) ->
list-chooser = new ChooseFont do
  node: '#demo-list-group', meta-url: "#fontinfo/meta.json", itemClass: \list-group-item, type: \list, base: fontbase
list-chooser.init!
[modal-chooser, list-chooser, dropdown-chooser].map ->
  it.on \choose, (font) ->
    <- font.sync textarea.value, _
    textarea.style.fontFamily = font.name

filter = {name: '', category: ''}
document.querySelector '#demo-modal .btn-group' .addEventListener \click, (e) ->
  Array.from(e.target.parentNode.childNodes).map -> it.classList.remove \active
  category = (e.target.innerText or '').replace(' ', '_').toUpperCase!
  if filter.category == category => filter.category = null
  else
    e.target.classList.add \active
    filter.category = category
  modal-chooser.filter filter
document.querySelector '#demo-modal input' .addEventListener \keyup, (e) ->
  filter.name = e.target.value
  modal-chooser.filter filter

xfl.load "#fontbase/CroissantOne-Regular.ttf"
xfl.load "#fontbase/Gafata-Regular.ttf"
