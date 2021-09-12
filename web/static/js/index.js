var fontbase, fontinfo, textarea, modalChooser, ldcv;
fontbase = "https://plotdb.github.io/xl-fontset/alpha";
fontbase = "assets/font/links";
fontinfo = "assets/font/meta";
textarea = document.querySelector('#demo-textarea');
modalChooser = new xfc({
  root: '.ldcv .xfc',
  metaRoot: 'assets/fonts/meta',
  fontRoot: 'assets/fonts/links'
});
modalChooser.init();
window.ldcv = ldcv = new ldCover({
  root: '.ldcv'
});
modalChooser.on('choose', function(f){
  window.ldcv.toggle(false);
  textarea.style.fontFamily = f.name;
  return f.sync(textarea.value);
});