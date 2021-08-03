var fontbase, fontinfo, textarea, modalChooser, ldcv;
fontbase = "https://plotdb.github.io/xl-fontset/alpha";
fontbase = "assets/font/links";
fontinfo = "assets/font/meta";
textarea = document.querySelector('#demo-textarea');
modalChooser = new xfc({
  root: '.ldcv .xfc',
  metaUrl: fontinfo + "/meta.json",
  base: fontbase,
  metaRoot: 'assets/fonts/meta',
  fontRoot: 'assets/fonts/links'
});
modalChooser.init();
modalChooser.on('choose', function(){
  return ldcv.toggle(false);
});
window.ldcv = ldcv = new ldCover({
  root: '.ldcv'
});
modalChooser.on('choose', function(f){
  window.ldcv.toggle('false');
  textarea.style.fontFamily = f.name;
  return f.sync(textarea.value);
});
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