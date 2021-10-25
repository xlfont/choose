(function(it){
  return it.apply({});
})(function(){
  var textarea, base, this$ = this;
  textarea = document.querySelector('#demo-textarea');
  base = "assets/fonts";
  base = "https://xlfont.maketext.io";
  return i18next.init({
    supportedLng: ['en', 'zh-TW'],
    fallbackLng: 'zh-TW'
  }).then(function(){
    var modalChooser, ldcv;
    modalChooser = new xfc({
      root: '.ldcv .xfc',
      meta: base + "/meta",
      links: base + "/links",
      i18n: i18next
    });
    this$.view = new ldview({
      root: document.body,
      action: {
        click: {
          choose: function(){
            return ldcv.toggle();
          }
        }
      }
    });
    modalChooser.init();
    this$.ldcv = ldcv = new ldcover({
      root: '.ldcv'
    });
    this$.ldcv.on('toggle.on', function(){
      return modalChooser.render();
    });
    return modalChooser.on('choose', function(f){
      this$.ldcv.toggle(false);
      if (!f) {
        return;
      }
      textarea.style.fontFamily = f.name;
      return f.sync(textarea.value);
    });
  });
});