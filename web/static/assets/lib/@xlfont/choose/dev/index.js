(function(){
  var once, i18n, xfc;
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
        q.splice(0).map(function(it){
          return it.rej(e);
        });
        return Promise.reject(e);
      });
    };
  };
  i18n = {
    "zh-TW": {
      "Category": "分類",
      "Subset": "子集",
      "Name": "名稱",
      "Use Your Own Font": "上傳",
      "or": "或",
      "Cancel": "取消"
    }
  };
  xfc = function(opt){
    var this$ = this;
    opt == null && (opt = {});
    this.opt = opt;
    this._url = {
      meta: opt.meta,
      links: opt.links
    };
    ['meta', 'links'].map(function(n){
      if (!this$._url[n] && xfc._url[n]) {
        return this$._url[n] = xfc._url[n];
      }
    });
    this.root = typeof opt.root === 'string'
      ? document.querySelector(opt.root)
      : opt.root;
    this._initRender = opt.initRender != null ? opt.initRender : false;
    this.evtHandler = {};
    if (this.root) {
      this.ldld = new ldloader({
        container: this.root,
        autoZ: true,
        className: 'ldld full'
      });
    }
    this.i18n = opt.i18n || {
      t: function(it){
        return it;
      }
    };
    this.init = once(function(){
      return this$._init();
    });
    return this;
  };
  xfc.url = function(o){
    o == null && (o = {});
    return !arguments.length
      ? xfc._url || {}
      : import$(xfc._url || (xfc._url = {}), o);
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
    config: function(opt){
      var this$ = this;
      opt == null && (opt = {});
      ['state', 'upload', 'order'].forEach(function(it){
        if (opt[it] != null) {
          return this$.opt[it] = opt[it];
        }
      });
      return this.init().then(function(){
        if (opt.order && this$.meta) {
          this$.meta.family.sort(this$.opt.order);
        }
        return this$.render();
      });
    },
    load: function(opt){
      var this$ = this;
      return this.init().then(function(){
        var family, ref$, font, that, s, w, path;
        if (!opt) {
          return null;
        }
        if ((xfc._customFont || (xfc._customFont = {}))[opt.name]) {
          return xfc._customFont[opt.name];
        }
        family = typeof opt === 'number'
          ? this$.meta.family[opt]
          : typeof opt === 'string'
            ? this$.meta.family.filter(function(it){
              return it.n.toLowerCase() === opt.toLowerCase();
            })[0]
            : opt.name ? this$.meta.family.filter(function(it){
              return it.n.toLowerCase() === opt.name.toLowerCase();
            })[0] : opt;
        if (!family) {
          return Promise.reject((ref$ = new Error(), ref$.message = "font not found", ref$.id = 404, ref$));
        }
        font = family.fonts[0];
        if (that = font.xfont) {
          return Promise.resolve(that);
        }
        s = this$.meta.index.style[font.s];
        w = this$.meta.index.weight[font.w];
        path = this$._url.links + "/" + family.n + "/" + s + "/" + w + (font.x ? '' : '.ttf');
        return xfl.load({
          path: path,
          name: family.n
        }).then(function(f){
          f.limited = this$._limited({
            font: opt
          });
          return font.xfont = f;
        });
      });
    },
    _limited: function(arg$){
      var font, isUpload, fn, limited;
      font = arg$.font, isUpload = arg$.isUpload;
      fn = isUpload || !in$(font, this.meta.family) ? 'upload' : 'state';
      limited = !!(typeof this.opt[fn] !== 'function'
        ? false
        : this.opt[fn]({
          font: font,
          type: 'limited'
        }));
      if (font) {
        font.limited = limited;
      }
      return limited;
    },
    render: function(){
      var _, this$ = this;
      this.ldld.on();
      _ = function(){
        return this$.init().then(function(){
          this$.view.render();
          this$.ldld.off();
          return this$._rendered = true;
        });
      };
      if (this._rendered) {
        return _();
      }
      return new Promise(function(res, rej){
        return setTimeout(function(){
          return _().then(function(it){
            return res(it);
          });
        }, 50);
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
            this$.meta.family.forEach(function(n, i){
              return n.i = i;
            });
            this$.meta.family = this$.meta.family.filter(function(it){
              return it.n;
            });
            if (this$.opt.order) {
              this$.meta.family.sort(this$.opt.order);
            }
          } catch (e$) {
            e = e$;
            return rej(e);
          }
          return res();
        });
        xhr.open('GET', this$._url.meta + "/meta.json");
        xhr.onerror = function(it){
          return rej(it);
        };
        return xhr.send();
      });
      return p.then(function(){
        var k, ref$, v;
        if (!this$.root) {
          return;
        }
        this$.cfg = {};
        if (this$.i18n.addResourceBundle) {
          for (k in ref$ = i18n) {
            v = ref$[k];
            this$.i18n.addResourceBundle(k, '@plotdb/choose', v, true, true);
          }
          Array.from(this$.root.querySelectorAll('[t]')).map(function(n){
            return n.textContent = this$.i18n.t("@plotdb/choose:" + n.textContent);
          });
        }
        return this$.view = new ldview({
          initRender: this$._initRender,
          root: this$.root,
          action: {
            input: {
              search: function(arg$){
                var node;
                node = arg$.node;
                this$.cfg.keyword = node.value || '';
                return this$.view.render(['font']);
              }
            },
            click: {
              cancel: function(){
                return this$.fire('choose', null);
              }
            },
            change: {
              upload: function(arg$){
                var node, file, id, url, font;
                node = arg$.node;
                file = node.files ? node.files[0] : null;
                if (!file) {
                  return node.value = '';
                }
                this$.ldld.on();
                id = "custom-" + (parseInt(Math.random() * Date.now()) + Date.now()).toString(36);
                url = URL.createObjectURL(file);
                (xfc._customFont || (xfc._customFont = {}))[id] = font = new xfl.xlfont({
                  path: url,
                  name: id,
                  isXl: false
                });
                this$._limited({
                  font: font,
                  upload: true
                });
                return font.init()['finally'](function(){
                  node.value = '';
                  this$.fire('load.end');
                  return this$.ldld.off();
                }).then(function(){
                  return this$.fire('choose', font);
                })['catch'](function(it){
                  console.error("[@xlfont/choose] font load failed: ", it);
                  return this$.fire('load.fail', it);
                });
              }
            }
          },
          init: {
            "cur-subset": function(arg$){
              var node;
              node = arg$.node;
              if (typeof BSN != 'undefined' && BSN !== null) {
                return new BSN.Dropdown(node);
              }
            },
            "cur-cat": function(arg$){
              var node;
              node = arg$.node;
              if (typeof BSN != 'undefined' && BSN !== null) {
                return new BSN.Dropdown(node);
              }
            }
          },
          handler: {
            "upload-button": function(arg$){
              var node;
              node = arg$.node;
              return node.classList.toggle('limited', !!this$._limited({
                isUpload: true
              }));
            },
            "cur-subset": function(arg$){
              var node;
              node = arg$.node;
              node.textContent = this$.cfg.subset || 'all';
              return node.classList.toggle('active', !!(this$.cfg.subset && this$.cfg.subset !== 'all'));
            },
            "cur-cat": function(arg$){
              var node;
              node = arg$.node;
              node.textContent = this$.cfg.category || 'all';
              return node.classList.toggle('active', !!(this$.cfg.category && this$.cfg.category !== 'all'));
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
            "font-list": function(arg$){
              var node, w;
              node = arg$.node;
              w = this$.meta.dim.width;
              return node.style.gridTemplateColumns = "repeat(auto-fill," + w + "px)";
            },
            font: {
              list: function(){
                return this$.meta.family;
              },
              host: typeof vscroll != 'undefined' && vscroll !== null ? vscroll.fixed : void 8,
              key: function(it){
                return it.n;
              },
              action: {
                click: function(arg$){
                  var node, data;
                  node = arg$.node, data = arg$.data;
                  this$.ldld.on();
                  this$.fire('load.start');
                  return this$.load(data)['finally'](function(){
                    this$.fire('load.end');
                    return this$.ldld.off();
                  }).then(function(it){
                    return this$.fire('choose', it);
                  })['catch'](function(it){
                    console.error("[@xlfont/choose] font load failed: ", it);
                    return this$.fire('load.fail', it);
                  });
                }
              },
              handler: function(arg$){
                var node, data, ref$, k, c, s, idx;
                node = arg$.node, data = arg$.data;
                ref$ = [this$.cfg.keyword, this$.cfg.category, this$.cfg.subset, this$.meta.index], k = ref$[0], c = ref$[1], s = ref$[2], idx = ref$[3];
                node.classList.toggle('limited', this$._limited({
                  font: data
                }));
                return node.classList.toggle('d-none', !data.n || (k && !~('' + data.n + data.d).toLowerCase().indexOf(k.toLowerCase())) || !(!c || c === 'all' || idx.category.indexOf(c) === data.c) || !(!s || s === 'all' || in$(idx.subset.indexOf(s), data.s)));
              },
              init: function(arg$){
                var node, data, idx, col, row, p, w, h, n, b;
                node = arg$.node, data = arg$.data;
                idx = data.i;
                col = idx % this$.meta.dim.col;
                row = Math.floor(idx / this$.meta.dim.col);
                p = this$.meta.dim.padding;
                w = this$.meta.dim.width;
                h = this$.meta.dim.height;
                n = node.querySelector('[ld=name]');
                b = node.querySelector('[ld=preview]');
                node.style;
                import$(b.style, {
                  width: w + "px",
                  height: h + "px",
                  backgroundImage: "url(" + this$._url.meta + "/sprite.min.png)",
                  backgroundPosition: -(w + p) * col + "px " + -(h + p) * row + "px"
                });
                return n.textContent = data.n;
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
