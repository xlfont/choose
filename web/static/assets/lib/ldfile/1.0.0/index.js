(function(){
  var loadFile, ldfile;
  loadFile = function(f, t, e){
    t == null && (t = 'binary');
    return new Promise(function(res, rej){
      var fr;
      fr = new FileReader();
      fr.onload = function(){
        return res({
          result: fr.result,
          file: f
        });
      };
      if (t === 'dataurl') {
        return fr.readAsDataURL(f);
      } else if (t === 'text') {
        return fr.readAsText(f, e || 'utf-8');
      } else if (t === 'binary') {
        return fr.readAsBinaryString(f);
      } else if (t === 'arraybuffer' || t === 'blob') {
        return fr.readAsArrayBuffer(f);
      } else if (t === 'bloburl') {
        return res({
          result: URL.createObjectURL(f),
          file: f
        });
      } else {
        return rej(new Error("[ldfile] un-supported type"));
      }
    });
  };
  ldfile = function(opt){
    var root, fromPrompt, this$ = this;
    opt == null && (opt = {});
    import$(this, {
      evtHandler: {},
      opt: opt,
      root: root = typeof opt.root === 'string'
        ? document.querySelector(opt.root)
        : opt.root,
      type: opt.type || 'binary',
      ldcv: opt.ldcv || null,
      encoding: opt.forceEncoding
    });
    fromPrompt = function(){
      return new Promise(function(res, rej){
        var ret;
        return res(ret = prompt("encoding:", "utf-8"));
      });
    };
    this.root.addEventListener('change', function(e){
      var files, promise;
      files = e.target.files;
      if (!files.length) {
        return;
      }
      promise = this$.type === 'text' && !opt.forceEncoding
        ? (this$.ldcv
          ? this$.ldcv.get()
          : fromPrompt()).then(function(it){
          return this$.encoding = it;
        })
        : Promise.resolve();
      return promise.then(function(){
        return Promise.all(Array.from(files).map(function(f){
          return loadFile(f, this$.type, this$.encoding);
        }));
      }).then(function(it){
        return this$.fire('load', it);
      });
    });
    return this;
  };
  ldfile.prototype = import$(Object.create(Object.prototype), {
    on: function(n, cb){
      var ref$;
      return ((ref$ = this.evtHandler)[n] || (ref$[n] = [])).push(cb);
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
    }
  });
  import$(ldfile, {
    fromURL: function(u, t, e){
      return new Promise(function(res, rej){
        var r;
        r = new XMLHttpRequest();
        r.open('GET', u, true);
        r.responseType = 'blob';
        r.onload = function(){
          return loadFile(r.response, t, e).then(res)['catch'](rej);
        };
        return r.send();
      });
    },
    fromFile: function(f, t, e){
      return loadFile(f, t, e);
    },
    download: function(opt){
      var that, href, n;
      opt == null && (opt = {});
      if (that = opt.href) {
        href = that;
      } else {
        href = URL.createObjectURL((that = opt.blob)
          ? that
          : new Blob([opt.data], {
            type: opt.mime
          }));
      }
      n = document.createElement('a');
      n.setAttribute('href', href);
      n.setAttribute('download', opt.name) || 'untitled';
      document.body.appendChild(n);
      n.click();
      return document.body.removeChild(n);
    }
  });
  if (typeof module != 'undefined' && module !== null) {
    module.exports = ldfile;
  } else if (typeof window != 'undefined' && window !== null) {
    window.ldfile = ldfile;
  }
  function import$(obj, src){
    var own = {}.hasOwnProperty;
    for (var key in src) if (own.call(src, key)) obj[key] = src[key];
    return obj;
  }
}).call(this);
