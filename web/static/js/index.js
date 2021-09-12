var textarea, base;
textarea = document.querySelector('#demo-textarea');
base = "https://xlfont.github.io/sample-set";
i18next.init({
  supportedLng: ['en', 'zh-TW'],
  fallbackLng: 'zh-TW'
}).then(function(){
  var modalChooser, ldcv;
  modalChooser = new xfc({
    root: '.ldcv .xfc',
    metaRoot: base + "/meta",
    fontRoot: base + "/links",
    i18n: i18next
  });
  modalChooser.init();
  window.ldcv = ldcv = new ldCover({
    root: '.ldcv'
  });
  return modalChooser.on('choose', function(f){
    window.ldcv.toggle(false);
    if (!f) {
      return;
    }
    textarea.style.fontFamily = f.name;
    return f.sync(textarea.value);
  });
});