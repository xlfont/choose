require! <[fs fs-extra path js-yaml yargs @plotdb/opentype.js progress colors svg2png sharp pngquant]>

lib = path.dirname fs.realpathSync __filename

sample-texts =
  "bengali": "নমুনা পাঠ"
  "khmer": "អត្ថបទគំរូ"
  "adlam": "𞤁𞤢𞤲𞤣𞤢𞤴𞤯𞤫 𞤂𞤫𞤻𞤮𞤤"
  "arabic": "الْأَبْجَدِيَّة الْعَرَبِيَّة"
  "hebrew": "אָלֶף־בֵּית עִבְרִי"
  "anatolian-hieroglyphs": "𔐀𔐁𔐂𔐃𔐄𔐅𔐆𔐇"
  "armenian": "Հայոց գրեր"

# sample command:
# lsc build.ls -- ../../cdn/files/ -l links -o meta-sample/ -w 190 -s 18 -f 28 -p 2

argv = yargs
  .usage "usage: npx xfc font-dir [-o meta-output-dir] [-l link-output-dir] [-w sample-image-width] [-h sample-image-height] [-f font-size]"
  .option \link, do
    alias: \l
    description: "link output directory. default `./output/links/`"
    type: \string
  .option \output, do
    alias: \o
    description: "meta output directory. default `./output/meta/`"
    type: \string
  .option \font-size, do
    alias: \f
    description: "default font size. default 48, auto shrink if needed."
    type: \number
  .option \sample-image-width, do
    alias: \w
    description: "font sample image width, default 400"
    type: \number
  .option \sample-image-height, do
    alias: \h
    description: "font sample image height, default 50"
    type: \number
  .option \sample-per-row, do
    alias: \c
    description: "how many samples per row. default 5"
    type: \number
  .option \padding, do
    alias: \p
    description: "image padding. default 10"
    type: \number
  .help \help
  .check (argv, options) ->
    if !argv._.0 => throw new Error("missing font dir")
    return true
  .argv

dim =
  width: argv.w or 400
  height: argv.h or 50
  col: argv.c or 5
  padding: if argv.p? => argv.p else 10
  fsize: argv.f or 48

root =
  files: argv._.0
  links: argv.l or 'output/links'
  meta: argv.o or 'output/meta'

fs-extra.ensure-dir-sync root.links
fs-extra.ensure-dir-sync root.meta

families = []
index = category: [], style: [], subset: [], weight: []
unicode-ranges = JSON.parse(fs.read-file-sync path.join(lib, "data", "unicode-ranges.json") .toString!)
  .filter -> it and it.0
unicode-ranges.map -> it.2 = it.2.toLowerCase!

parse-pb = (root, file) ->
  data = fs.read-file-sync file .toString!split '\n' .filter -> it
  [fonts, font] = [[], null]
  family = {fonts}
  for line in data
    if /^\s*#/.exec(line) => continue # comment
    else if /^fonts\s*{/.exec(line) => # begin of fonts section
      if font => fonts.push font
      font = {}
    else if /^}/.exec(line) =>
      if font => fonts.push font
      font = null
    else if /^\s*(\S+)\s*:\s*(.+)/.exec(line) =>
      [k, v] = [that.1.trim!, that.2.trim!]
      if /"([^"]+)"/.exec(v) => v = that.1
      if k == \category => v = (v or 'sans serif').replace(/_/g,' ')
      # Google use `subsets`. but we internally use `subset` to prevent confusion.
      if k == \subsets => k = \subset
      if Array.isArray(index[k]) =>
        v = (v or '').toLowerCase!trim!
        index[k].push v
      if font =>
        if k in <[style weight]> => font[k.0] = v
        else if k == \filename => font.src = path.join(root, v)
      else
        if k == \name => family[k.0] = v
        else if k == \category => family.c = v
        else if k == \subset => family[][k.0].push v
        # this is incorrect, but fast to implement.
        else if k == \value and !sample-texts[family.n] => sample-texts[family.n] = v
        else if k == \license => family.license = v
    else
      # simply ignored.
      # we may need to handle this for more complicated font format, such as variable fonts.
      # console.log "parse error", line
  if family.license != \OFL => return null
  delete family.license
  return family

parse-yaml = (root, file) ->
  ret = js-yaml.load fs.read-file-sync file
  ret = ret.map (d) ->
    family = {fonts: [], n: d.name, c: (d.category or 'sans serif').toLowerCase!trim!}
    index.category.push family.c
    if d.displayname => family.d = d.displayname
    # Google use `subsets` in METADATA.pb, so we use `subsets` too in metadat.yaml.
    # but anyway we internally use `subset` to prevent unnecessary confusion.
    if d.subsets =>
      family.s = d.subsets.filter(->it).map -> it.toLowerCase!trim!
      index.subset ++= family.s
    for k,v of d.style =>
      index.style.push k
      for f in v =>
        w = "#{(f.weight or 400)}"
        index.weight.push w
        font = {s: k, w: w, src: path.join(root, f.filename)}
        if f.xfl => font.x = true
        family.fonts.push font
    family
  return ret

recurse = (root) ->
  files = fs.readdir-sync root .map -> "#root/#it"
  for file in files =>
    if fs.stat-sync(file).is-directory! =>
      recurse(file)
      continue
    if !/METADATA.pb|metadata.yaml/.exec(file) => continue
    family = if /METADATA.pb/.exec(file) => parse-pb(root, file)
    else if /metadata.yaml/.exec(file) => parse-yaml(root, file)
    else null
    if Array.isArray(family) => families ++= family else if family => families.push family

recurse root.files
for k,v of index =>
  index[k] = Array.from(new Set(index[k].filter(-> it)))
  index[k] = index[k].sort (a,b) -> if a > b => 1 else if a < b => -1 else 0

for family in families =>
  for f in family.fonts =>
    f.s = index.style.indexOf(f.s)
    f.w = index.weight.indexOf(f.w)
  family.s = family.[]s.map -> index.subset.indexOf(it)
  family.c = index.category.indexOf(family.c)

for k,v of index =>
  index[k] = index[k].map -> it.toLowerCase!replace /sans_serif/, 'sans serif'

output = {family: families, index, dim}

render-fonts = []
for family in families =>
  paths = []
  for f in family.fonts =>
    des-path = path.join(root.links, family.n, index.style[f.s])
    if f.x => des-file = path.join(root.links, family.n, index.style[f.s], index.weight[f.w])
    else des-file = path.join(root.links, family.n, index.style[f.s], index.weight[f.w] + '.ttf')
    paths.push {s: f.s, w: f.w, x: f.x, p: des-file}
    fs-extra.ensure-dir-sync des-path
    try
      if fs.lstat-sync(des-file) => fs.unlink-sync des-file
    catch e
      #
    fs.symlink-sync path.relative(des-path, f.src), des-file
    delete f.src
  paths.sort (a,b) ->
    [v1,v2] = [0,0]
    [a, b] = [a, b].map (d) ->
      (if index.style[d.s] == \normal => 0 else 100) + (Math.abs(+index.weight[d.w] - 400) / 10)
    return a - b
  if !paths.0 => continue
  render-fonts.push {
    name: (family.d or family.n)
    path: if paths.0.x => path.join(paths.0.p, "all.ttf") else paths.0.p
    subset: family.s.map(-> index.subset[it])
  }

fs.write-file-sync path.join(root.meta, 'meta.json'), JSON.stringify(output)

get-text = (font, text, meta = {}) ->
  codes = text.split('').map -> it.charCodeAt(0)
  unicodes = []
  [v for k,v of font.glyphs.glyphs].map ->
    (it.unicodes or []).map -> unicodes.push it
    unicodes.push it.unicode
  unicodes = Array.from(new Set(unicodes))
  unicodes.sort (a,b) -> a - b
  if codes.filter(-> ~unicodes.indexOf(it)).length < codes.length =>
    text = ""
    for k,v of sample-texts => if k in meta.subset => text = v
    if !text =>
      if sample-texts[meta.name] => text = (that).substring(0, 16)
    if !text =>
      range = unicode-ranges.filter(-> (it.2 != 'menu' and it.2 in meta.subset)).0
      if range => for i from range.0 til (range.0 + 8) => text += String.fromCharCode(i)
    if !text =>
      unicodes = unicodes.filter -> (it > 64 and it <= 89) or (it >= 97 and it <= 122) or it > 256
      idx = (Math.floor(unicodes.length / 2) + 4) <? unicodes.length
      unicodes = [unicodes[i] for i from ((idx - 8) >? 0) til idx]
      text = unicodes
        .map(-> String.fromCharCode(it))
        .join('')
  return text

render-font = (meta, row = 0, col = 0) ->
  opentype.load meta.path .then (font) ->
    text = get-text font, meta.name, meta
    path = font.getPath(text, 0, 0, dim.fsize)
    box = path.getBoundingBox!
    box.width = (box.x2 - box.x1) or 1
    box.height = (box.y2 - box.y1) or 1
    if box.width >= (dim.width - dim.fsize) or box.height >= dim.height =>
      rate = Math.min((dim.width - dim.fsize) / box.width, dim.height / box.height)
      path = font.getPath(text, 0, 0, dim.fsize * rate)
      box = path.getBoundingBox!
      box.width = (box.x2 - box.x1) or 1
      box.height = (box.y2 - box.y1) or 1
    d = path.toPathData!
    x = col * (dim.width + dim.padding) + (dim.width - box.width) / 2 - box.x1
    y = row * (dim.height + dim.padding) + (dim.height - box.height) / 2 - box.y1
    return """<path d="#d" transform="translate(#x,#y)"/>"""

render-all = -> new Promise (res, rej) ->

  bar = new progress(
    "   convert [#{':bar'.yellow}] #{':percent'.cyan} :etas",
    { total: render-fonts.length + 1, width: 60, complete: '#' }
  )
  paths = []
  _ = (idx = 0) ->
    bar.tick!
    if !render-fonts[idx] =>
      w = (dim.width + dim.padding) * dim.col - dim.padding
      h = (dim.height + dim.padding) * Math.ceil(paths.length / dim.col) - dim.padding
      ret = """
      <?xml version="1.0" encoding="utf-8"?>
      <svg xmlns="http://www.w3.org/2000/svg" width="#w" height="#h" viewBox="0 0 #w #h">
      #{paths.join('')}
      </svg>
      """
      return res ret
    row = (idx - (idx % dim.col)) / dim.col
    col = idx % dim.col
    render-font render-fonts[idx], row, col
      .then (p) ->
        paths.push p
        _ idx + 1
      .catch (e) ->
        console.log "failed when rendering #idx font: ", render-fonts[idx], e
        _ idx + 1
  _!

console.log "   generate sprite svg...".cyan
render-all!
  .then (svg) ->
    # write svg file ( may be quite huge ) if necessary
    # fs.write-file-sync path.join(root.meta, 'sprite.svg'), svg
    console.log "   generate sprite png file...".cyan
    # alernatively, use svg2png.
    # however, somewhat svg2png ( with phantomjs ) doesn't work in debian linux
    #svg2png Buffer.from(svg)
    #  .then (buf) -> fs.write-file-sync path.join(root.meta, 'sprite.png'), buf
    (res, rej) <- new Promise _
    sharp(Buffer.from(svg))
      .png!toFile(path.join(root.meta, 'sprite.png'), (e) -> if e => rej(e) else res!)
  .then ->
    console.log "   optimize sprite png file...".cyan
    (res, rej) <- new Promise _
    pq = new pngquant [8, '--quality', '30-40']
    ret = fs.createReadStream path.join(root.meta, 'sprite.png')
      .pipe pq
      .pipe fs.createWriteStream(path.join(root.meta, 'sprite.min.png'))
    ret.on \finish, -> return res!
  .then ->
    console.log "   generate sprite webp file...".cyan
    (res, rej) <- new Promise _
    sharp(path.join(root.meta, 'sprite.min.png'))
      .webp({quality: 80})
      .toFile(path.join(root.meta, 'sprite.webp'), (e) -> if e => rej(e) else res!)
  .then ->
    console.log "   done.".green
