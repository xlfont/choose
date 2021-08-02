(function(){
  var xfc;
  xfc = function(opt){
    opt == null && (opt = {});
    this.metaRoot = opt.metaRoot;
    this.fontRoot = opt.fontRoot;
    this.root = typeof this.root === 'string'
      ? document.querySelector(opt.root)
      : opt.root;
    this.evtHandler = {};
    return this;
  };
  xfc.prototype = import$(Object.create(Object.prototype), {
    on: function(n, cb){
      var this$ = this;
      return (Array.isArray(n)
        ? n
        : [n]).map(function(n){
        var ref$;
        return ((ref$ = this$.evtHandler)[n] || (ref$[n] = [])).push(cb);
      });
    },
    fire: function(n){
      var v, res$, i$, to$, ref$, len$, cb, results$ = [];
      res$ = [];
      for (i$ = 1, to$ = arguments.length; i$ < to$; ++i$) {
        res$.push(arguments[i$]);
      }
      v = res$;
      for (i$ = 0, len$ = (ref$ = this.evtHandler[n] || []).length; i$ < len$; ++i$) {
        cb = ref$[i$];
        results$.push(cb.apply(this, v));
      }
      return results$;
    },
    init: function(){
      var p, this$ = this;
      p = new Promise(function(res, rej){
        var xhr;
        xhr = new XMLHttpRequest();
        xhr.addEventListener('readystatechange', function(){
          var e;
          if (xhr.readyState !== 4) {
            return;
          }
          if (xhr.status !== 200) {
            return rej(xhr.responseText);
          }
          try {
            this$.meta = JSON.parse(xhr.responseText);
          } catch (e$) {
            e = e$;
            return rej(e);
          }
          return res();
        });
        xhr.open('GET', this$.metaRoot + "/meta.json");
        xhr.onerror = function(it){
          return rej(it);
        };
        return xhr.send();
      });
      return p.then(function(){
        console.log(this$.meta);
        return this$.view = new ldview({
          root: this$.root,
          handler: {
            category: {
              list: function(){
                return this$.meta.index.category;
              },
              handler: function(arg$){
                var node, data;
                node = arg$.node, data = arg$.data;
                return node.textContent = data;
              }
            },
            subset: {
              list: function(){
                return this$.meta.index.subsets;
              },
              handler: function(arg$){
                var node, data;
                node = arg$.node, data = arg$.data;
                return node.textContent = data;
              }
            },
            font: {
              list: function(){
                return this$.meta.family;
              },
              key: function(it){
                return it.name;
              },
              handler: function(arg$){
                var node, data, idx, col, row, w, h;
                node = arg$.node, data = arg$.data, idx = arg$.idx;
                node.textContent = ' ';
                col = idx % this$.meta.dim.col;
                row = Math.floor(idx / this$.meta.dim.col);
                w = this$.meta.dim.width + this$.meta.dim.padding;
                h = this$.meta.dim.height + this$.meta.dim.padding;
                return import$(node.style, {
                  width: w + "px",
                  height: h + "px",
                  backgroundImage: "url(" + this$.metaRoot + "/sprite.min.png)",
                  backgroundPosition: -w * col + "px " + -h * row + "px",
                  margin: '.25em'
                });
              }
            }
          }
        });
      });
    }
  });
  if (typeof module != 'undefined' && module !== null) {
    module.exports = xfc;
  } else if (typeof window != 'undefined' && window !== null) {
    window.xfc = xfc;
  }
  function import$(obj, src){
    var own = {}.hasOwnProperty;
    for (var key in src) if (own.call(src, key)) obj[key] = src[key];
    return obj;
  }
}).call(this);
