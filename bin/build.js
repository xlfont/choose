#!/usr/bin/env node
(function(){
  var fs, fsExtra, path, jsYaml, yargs, opentype, progress, colors, svg2png, pngquant, argv, dim, root, families, index, parsePb, parseYaml, recurse, k, v, i$, len$, family, j$, ref$, len1$, f, output, renderFonts, paths, desPath, desFile, e, getText, renderFont, renderAll;
  fs = require('fs');
  fsExtra = require('fs-extra');
  path = require('path');
  jsYaml = require('js-yaml');
  yargs = require('yargs');
  opentype = require('@plotdb/opentype.js');
  progress = require('progress');
  colors = require('colors');
  svg2png = require('svg2png');
  pngquant = require('pngquant');
  argv = yargs.usage("usage: npx xfc font-dir [-o meta-output-dir] [-l link-output-dir] [-w sample-image-width] [-h sample-image-height] [-f font-size]").option('link', {
    alias: 'l',
    description: "link output directory. default `./output/links/`",
    type: 'string'
  }).option('output', {
    alias: 'o',
    description: "meta output directory. default `./output/meta/`",
    type: 'string'
  }).option('font-size', {
    alias: 'f',
    description: "default font size. default 48, auto shrink if needed.",
    type: 'number'
  }).option('sample-image-width', {
    alias: 'w',
    description: "font sample image width, default 400",
    type: 'number'
  }).option('sample-image-height', {
    alias: 's',
    description: "font sample image height, default 50",
    type: 'number'
  }).option('sample-per-row', {
    alias: 'c',
    description: "how many samples per row. default 5",
    type: 'number'
  }).option('padding', {
    alias: 'p',
    description: "image padding. default 10",
    type: 'number'
  }).help('help').alias('help', 'h').check(function(argv, options){
    if (!argv._[0]) {
      throw new Error("missing font dir");
    }
    return true;
  }).argv;
  dim = {
    width: argv.w || 400,
    height: argv.h || 50,
    col: argv.c || 5,
    padding: argv.p || 10,
    fsize: argv.f || 48
  };
  root = {
    files: argv._[0],
    links: argv.l || 'output/links',
    meta: argv.o || 'output/meta'
  };
  fsExtra.ensureDirSync(root.links);
  fsExtra.ensureDirSync(root.meta);
  families = [];
  index = {
    category: [],
    style: [],
    subset: [],
    weight: []
  };
  parsePb = function(root, file){
    var data, ref$, fonts, font, family, i$, len$, line, that, k, v, key$;
    data = fs.readFileSync(file).toString().split('\n').filter(function(it){
      return it;
    });
    ref$ = [[], null], fonts = ref$[0], font = ref$[1];
    family = {
      fonts: fonts
    };
    for (i$ = 0, len$ = data.length; i$ < len$; ++i$) {
      line = data[i$];
      if (/^\s*#/.exec(line)) {
        continue;
      } else if (/^fonts\s*{/.exec(line)) {
        if (font) {
          fonts.push(font);
        }
        font = {};
      } else if (/^}/.exec(line)) {
        fonts.push(font);
        font = null;
      } else if (that = /^\s*(\S+)\s*:\s*(.+)/.exec(line)) {
        ref$ = [that[1].trim(), that[2].trim()], k = ref$[0], v = ref$[1];
        if (that = /"([^"]+)"/.exec(v)) {
          v = that[1];
        }
        if (k === 'category') {
          v = (v || 'sans serif').replace(/_/g, ' ');
        }
        if (k === 'subsets') {
          k = 'subset';
        }
        if (Array.isArray(index[k])) {
          v = (v || '').toLowerCase().trim();
          index[k].push(v);
        }
        if (font) {
          if (k === 'style' || k === 'weight') {
            font[k[0]] = v;
          } else if (k === 'filename') {
            font.src = path.join(root, v);
          }
        } else {
          if (k === 'name') {
            family[k[0]] = v;
          } else if (k === 'category') {
            family.c = v;
          } else if (k === 'subset') {
            (family[key$ = k[0]] || (family[key$] = [])).push(v);
          }
        }
      } else {
        console.log("parse error", line);
      }
    }
    return family;
  };
  parseYaml = function(root, file){
    var ret;
    ret = jsYaml.load(fs.readFileSync(file));
    ret = ret.map(function(d){
      var family, k, ref$, v, i$, len$, f, w, font;
      family = {
        fonts: [],
        n: d.name,
        c: (d.category || 'sans serif').toLowerCase().trim()
      };
      index.category.push(family.c);
      if (d.displayname) {
        family.d = d.displayname;
      }
      if (d.subsets) {
        family.s = d.subsets.filter(function(it){
          return it;
        }).map(function(it){
          return it.toLowerCase().trim();
        });
        index.subset = index.subset.concat(family.s);
      }
      for (k in ref$ = d.style) {
        v = ref$[k];
        index.style.push(k);
        for (i$ = 0, len$ = v.length; i$ < len$; ++i$) {
          f = v[i$];
          w = (f.weight || 400) + "";
          index.weight.push(w);
          font = {
            s: k,
            w: w,
            src: path.join(root, f.filename)
          };
          if (f.xfl) {
            font.x = true;
          }
          family.fonts.push(font);
        }
      }
      return family;
    });
    return ret;
  };
  recurse = function(root){
    var files, i$, len$, file, family, results$ = [];
    files = fs.readdirSync(root).map(function(it){
      return root + "/" + it;
    });
    for (i$ = 0, len$ = files.length; i$ < len$; ++i$) {
      file = files[i$];
      if (fs.statSync(file).isDirectory()) {
        recurse(file);
        continue;
      }
      if (!/METADATA.pb|metadata.yaml/.exec(file)) {
        continue;
      }
      family = /METADATA.pb/.exec(file)
        ? parsePb(root, file)
        : /metadata.yaml/.exec(file) ? parseYaml(root, file) : null;
      if (Array.isArray(family)) {
        results$.push(families = families.concat(family));
      } else if (family) {
        results$.push(families.push(family));
      }
    }
    return results$;
  };
  recurse(root.files);
  for (k in index) {
    v = index[k];
    index[k] = Array.from(new Set(index[k].filter(fn$)));
    index[k] = index[k].sort(fn1$);
  }
  for (i$ = 0, len$ = families.length; i$ < len$; ++i$) {
    family = families[i$];
    for (j$ = 0, len1$ = (ref$ = family.fonts).length; j$ < len1$; ++j$) {
      f = ref$[j$];
      f.s = index.style.indexOf(f.s);
      f.w = index.weight.indexOf(f.w);
    }
    family.s = (family.s || (family.s = [])).map(fn2$);
    family.c = index.category.indexOf(family.c);
  }
  for (k in index) {
    v = index[k];
    index[k] = index[k].map(fn3$);
  }
  output = {
    family: families,
    index: index,
    dim: dim
  };
  renderFonts = [];
  for (i$ = 0, len$ = families.length; i$ < len$; ++i$) {
    family = families[i$];
    paths = [];
    for (j$ = 0, len1$ = (ref$ = family.fonts).length; j$ < len1$; ++j$) {
      f = ref$[j$];
      desPath = path.join(root.links, family.n, index.style[f.s]);
      if (f.x) {
        desFile = path.join(root.links, family.n, index.style[f.s], index.weight[f.w]);
      } else {
        desFile = path.join(root.links, family.n, index.style[f.s], index.weight[f.w] + '.ttf');
      }
      paths.push({
        s: f.s,
        w: f.w,
        x: f.x,
        p: desFile
      });
      fsExtra.ensureDirSync(desPath);
      try {
        if (fs.lstatSync(desFile)) {
          fs.unlinkSync(desFile);
        }
      } catch (e$) {
        e = e$;
      }
      fs.symlinkSync(path.relative(desPath, f.src), desFile);
      delete f.src;
    }
    paths.sort(fn4$);
    renderFonts.push({
      name: family.d || family.n,
      path: paths[0].x
        ? path.join(paths[0].p, "all.ttf")
        : paths[0].p
    });
  }
  fs.writeFileSync(path.join(root.meta, 'meta.json'), JSON.stringify(output));
  getText = function(font, text){
    var codes, unicodes, k, v;
    codes = text.split('').map(function(it){
      return it.charCodeAt(0);
    });
    unicodes = [];
    (function(){
      var ref$, results$ = [];
      for (k in ref$ = font.glyphs.glyphs) {
        v = ref$[k];
        results$.push(v);
      }
      return results$;
    }()).map(function(it){
      (it.unicodes || []).map(function(it){
        return unicodes.push(it);
      });
      return unicodes.push(it.unicode);
    });
    unicodes = Array.from(new Set(unicodes));
    unicodes.sort(function(a, b){
      return a - b;
    });
    if (codes.filter(function(it){
      return ~unicodes.indexOf(it);
    }).length < codes.length) {
      unicodes = unicodes.filter(function(it){
        return (it > 64 && it <= 89) || (it >= 97 && it <= 122) || it > 256;
      });
      text = unicodes.slice(0, 8).map(function(it){
        return String.fromCharCode(it);
      }).join('');
    }
    return text;
  };
  renderFont = function(meta, row, col){
    row == null && (row = 0);
    col == null && (col = 0);
    return opentype.load(meta.path).then(function(font){
      var text, path, box, rate, d, x, y;
      text = getText(font, meta.name);
      path = font.getPath(text, 0, 0, dim.fsize);
      box = path.getBoundingBox();
      box.width = box.x2 - box.x1 || 1;
      box.height = box.y2 - box.y1 || 1;
      if (box.width >= dim.width - dim.fsize || box.height >= dim.height) {
        rate = Math.min((dim.width - dim.fsize) / box.width, dim.height / box.height);
        path = font.getPath(text, 0, 0, dim.fsize * rate);
        box = path.getBoundingBox();
        box.width = box.x2 - box.x1 || 1;
        box.height = box.y2 - box.y1 || 1;
      }
      d = path.toPathData();
      x = col * (dim.width + dim.padding) + (dim.width - box.width) / 2 - box.x1;
      y = row * (dim.height + dim.padding) + (dim.height - box.height) / 2 - box.y1;
      return "<path d=\"" + d + "\" transform=\"translate(" + x + "," + y + ")\"/>";
    });
  };
  renderAll = function(){
    return new Promise(function(res, rej){
      var bar, paths, _;
      bar = new progress("   convert [" + ':bar'.yellow + "] " + ':percent'.cyan + " :etas", {
        total: renderFonts.length + 1,
        width: 60,
        complete: '#'
      });
      paths = [];
      _ = function(idx){
        var w, h, ret, row, col;
        idx == null && (idx = 0);
        bar.tick();
        if (!renderFonts[idx]) {
          w = (dim.width + dim.padding) * dim.col - dim.padding;
          h = (dim.height + dim.padding) * Math.ceil(paths.length / dim.col);
          ret = "<?xml version=\"1.0\" encoding=\"utf-8\"?>\n<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"" + w + "\" height=\"" + h + "\" viewBox=\"0 0 " + w + " " + h + "\">\n" + paths.join('') + "\n</svg>";
          return res(ret);
        }
        row = (idx - idx % dim.col) / dim.col;
        col = idx % dim.col;
        return renderFont(renderFonts[idx], row, col).then(function(p){
          paths.push(p);
          return _(idx + 1);
        })['catch'](function(e){
          console.log("failed when rendering " + idx + " font: ", renderFonts[idx], e);
          return _(idx + 1);
        });
      };
      return _();
    });
  };
  console.log("   generate sprite svg...".cyan);
  renderAll().then(function(svg){
    console.log("   generate sprite png file...".cyan);
    return svg2png(Buffer.from(svg));
  }).then(function(buf){
    return new Promise(function(res, rej){
      var pq, ret;
      fs.writeFileSync(path.join(root.meta, 'sprite.png'), buf);
      pq = new pngquant([8, '--quality', '30-40']);
      console.log("   optimize sprite png file...".cyan);
      ret = fs.createReadStream(path.join(root.meta, 'sprite.png')).pipe(pq).pipe(fs.createWriteStream(path.join(root.meta, 'sprite.min.png')));
      return ret.on('finish', function(){
        return res();
      });
    });
  }).then(function(){
    return console.log("   done.".green);
  });
  function fn$(it){
    return it;
  }
  function fn1$(a, b){
    if (a > b) {
      return 1;
    } else if (a < b) {
      return -1;
    } else {
      return 0;
    }
  }
  function fn2$(it){
    return index.subset.indexOf(it);
  }
  function fn3$(it){
    return it.toLowerCase().replace(/sans_serif/, 'sans serif');
  }
  function fn4$(a, b){
    var ref$, v1, v2;
    ref$ = [0, 0], v1 = ref$[0], v2 = ref$[1];
    ref$ = [a, b].map(function(d){
      return (index.style[d.s] === 'normal' ? 0 : 100) + Math.abs(+index.weight[d.w] - 400) / 10;
    }), a = ref$[0], b = ref$[1];
    return a - b;
  }
}).call(this);
