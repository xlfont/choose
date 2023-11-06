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
    var list, modalChooser, ldcv;
    list = ["Bevan", "ABeeZee", "Abel", "Abhaya Libre", "Abril Fatface", "Abyssinica SIL", "Aclonica", "Acme", "Actor", "Adamina", "Advent Pro", "Aguafina Script", "Akronim", "Aladin"];
    modalChooser = new xfc({
      root: '.ldcv .xfc',
      meta: base + "/meta",
      links: base + "/links",
      i18n: i18next,
      upload: function(){
        return true;
      },
      state: function(arg$){
        var font, idx, type;
        font = arg$.font, idx = arg$.idx, type = arg$.type;
        if (type === 'limited') {
          return in$(font.n, list) ? false : true;
        }
      },
      order: function(a, b){
        var ref$, an, bn, pa, pb;
        ref$ = [a.n.toLowerCase(), b.n.toLowerCase()], an = ref$[0], bn = ref$[1];
        ref$ = [in$(a.n, list), in$(b.n, list)], pa = ref$[0], pb = ref$[1];
        if (!pa !== !pb && (pa || pb)) {
          return pa ? -1 : 1;
        }
        if (an > bn) {
          return 1;
        } else if (an < bn) {
          return -1;
        } else {
          return 0;
        }
      }
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
      console.log("chosen font: ", f);
      this$.ldcv.toggle(false);
      if (!f) {
        return;
      }
      textarea.style.fontFamily = f.name;
      return f.sync(textarea.value);
    });
  });
});
function in$(x, xs){
  var i = -1, l = xs.length >>> 0;
  while (++i < l) if (x === xs[i]) return true;
  return false;
}