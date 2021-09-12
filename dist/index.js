(function(){
  var once, xfc;
  once = function(f, q){
    q == null && (q = []);
    return function(){
      if (q.s === 2) {
        return Promise.resolve();
      } else if (q.s === 1) {
        return new Promise(function(res, rej){
          return q.push({
            res: res,
            rej: rej
          });
        });
      }
      return Promise.resolve(q.s = 1).then(function(){
        return f();
      }).then(function(){
        q.s = 2;
        return q.splice(0).map(function(it){
          return it.res();
        });
      })['catch'](function(e){
        q.s = 0;
        return q.splice(0).map(function(it){
          return it.rej(e);
        });
      });
    };
  };
  xfc = function(opt){
    var this$ = this;
    opt == null && (opt = {});
    this.metaRoot = opt.metaRoot;
    this.fontRoot = opt.fontRoot;
    this.root = typeof this.root === 'string'
      ? document.querySelector(opt.root)
      : opt.root;
    this.evtHandler = {};
    this.init = once(function(){
      return this$._init();
    });
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
    load: function(opt){
      var family, font, that, s, w, path;
      family = typeof opt === 'number' ? this.meta.family[opt] : opt;
      font = family.fonts[0];
      if (that = font.xfont) {
        return Promise.resolve(that);
      }
      s = this.meta.index.style[font.s];
      w = this.meta.index.weight[font.w];
      path = this.fontRoot + "/" + family.n + "/" + s + "/" + w + (font.x ? '' : '.ttf');
      return xfl.load({
        path: path,
        name: family.n
      }).then(function(it){
        return font.xfont = it;
      });
    },
    _init: function(){
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
        this$.cfg = {};
        return this$.view = new ldview({
          root: this$.root,
          handler: {
            "cur-subset": function(arg$){
              var node;
              node = arg$.node;
              return node.textContent = this$.cfg.subset || 'All';
            },
            "cur-cat": function(arg$){
              var node;
              node = arg$.node;
              return node.textContent = this$.cfg.category || 'All';
            },
            category: {
              list: function(){
                return ['all'].concat(this$.meta.index.category);
              },
              action: {
                click: function(arg$){
                  var node, data;
                  node = arg$.node, data = arg$.data;
                  this$.cfg.category = data;
                  return this$.view.render(['font', 'cur-cat', 'category']);
                }
              },
              handler: function(arg$){
                var node, data;
                node = arg$.node, data = arg$.data;
                node.textContent = data;
                return node.classList.toggle('active', this$.cfg.category === data || (!this$.cfg.category && data === 'all'));
              }
            },
            subset: {
              list: function(){
                return ['all'].concat(this$.meta.index.subset);
              },
              action: {
                click: function(arg$){
                  var node, data;
                  node = arg$.node, data = arg$.data;
                  this$.cfg.subset = data;
                  return this$.view.render(['font', 'cur-subset', 'subset']);
                }
              },
              handler: function(arg$){
                var node, data;
                node = arg$.node, data = arg$.data;
                node.textContent = data;
                return node.classList.toggle('active', this$.cfg.subset === data || (!this$.cfg.subset && data === 'all'));
              }
            },
            font: {
              list: function(){
                return this$.meta.family;
              },
              key: function(it){
                return it.n;
              },
              action: {
                click: function(arg$){
                  var node, data, idx;
                  node = arg$.node, data = arg$.data, idx = arg$.idx;
                  this$.fire('load.start');
                  return this$.load(data)['finally'](function(){
                    return this$.fire('load.end');
                  }).then(function(it){
                    return this$.fire('choose', it);
                  })['catch'](function(it){
                    console.error("[@xlfont/choose] font load failed: ", it);
                    return this$.fire('load.fail', it);
                  });
                }
              },
              handler: function(arg$){
                var node, data, idx, ref$, c, s;
                node = arg$.node, data = arg$.data, idx = arg$.idx;
                ref$ = [this$.cfg.category, this$.cfg.subset, this$.meta.index], c = ref$[0], s = ref$[1], idx = ref$[2];
                return node.classList.toggle('d-none', !(!c || c === 'all' || idx.category.indexOf(c) === data.c) || !(!s || s === 'all' || in$(idx.subset.indexOf(s), data.s)));
              },
              init: function(arg$){
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
                  margin: 'auto'
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
  function in$(x, xs){
    var i = -1, l = xs.length >>> 0;
    while (++i < l) if (x === xs[i]) return true;
    return false;
  }
}).call(this);
