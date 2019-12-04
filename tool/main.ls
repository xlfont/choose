require! <[fs fs-extra path text-to-svg svg-path-bounds sharp pngquant progress colors svg2png]>

dim = {width: 400, height: 50, col: 5, padding: 10}
fontset-dir = "fontset"
scale-multiplier = 1.75

variants = <[Italic Regular Bold ExtraBold Medium SemiBold ExtraLight Light Thin Black BlackItalic BoldItalic ExtraBoldItalic MediumItalic LightItalic ThinItalic SemiBoldItalic ExtraLightItalic DemiBold Heavy UltraLight]>

metamap = {}
if fs.exists-sync(\meta.json) => metamap = JSON.parse(fs.read-file-sync \meta.json .toString!)

is-rect = ->
  ret = /^M(-?[0-9.]+)( |-?)([0-9.]+) ?L(-?[0-9.]+)( |-?)([0-9.]+) ?L(-?[0-9.]+)( |-?)([0-9.]+) ?L(-?[0-9.]+)( |-?)([0-9.]+) ?L(-?[0-9.]+)( |-?)([0-9.]+)/.exec(it)
  if !ret => return false
  if ret.1 == ret.13 and ret.1 == ret.10 and
  (ret.2 + ret.3) == (ret.5 + ret.6) and (ret.2 + ret.3) == (ret.14 + ret.15) and
  ret.4 == ret.7 and (ret.8 + ret.9) == (ret.11 + ret.12) => return true
  if ret.1 == ret.4 and ret.1 == ret.13 and ret.7 == ret.10 and
  (ret.2 + ret.3) == (ret.11 + ret.12) and (ret.2 + ret.3) == (ret.14 + ret.15) and
  (ret.5 + ret.6) == (ret.8 + ret.9) => return true
  return false

progress-bar = (total = 10, text = "converting") ->
  bar = new progress(
    "   #text [#{':bar'.yellow}] #{':percent'.cyan} :etas",
    { total: total, width: 60, complete: '#' }
  )
  return bar

get-font-list = (parent, fonthash = {}) ->
  files = fs.readdir-sync parent .map -> "#parent/#it"
  for file in files =>
    if fs.stat-sync file .is-directory! => get-font-list file, fonthash
    else if /\.ttf$/.exec(file) =>
      ret = path.basename(file).replace(/\.ttf$/, '').split(\-)
      if !ret.0 => continue
      [name,family] = if ret[* - 1] in variants => [ret.slice(0, ret.length - 1).join('-'), ret[* - 1]]
      else [ret.join('-'), null]
      is-set = fs.exists-sync "#fontset-dir/#name/charmap.txt"
      if !fonthash[name] => fonthash[name] = {name: name, family: {}}
      if is-set => fonthash[name].is-set = true
      if family => fonthash[name].family[family] = file
      else => fonthash[name].path = file
  return fonthash

path-bounds = (d) ->
  ret = svg-path-bounds(d)
  return {x: ret.0, y: ret.1, width: ret.2 - ret.0, height: ret.3 - ret.1}

process-font = (font) -> new Promise (res, rej) ->
  <- setTimeout _, 0
  try
    family = ([{style: null, path: font.path}] ++ [{style: k,path: v} for k,v of font.family]).filter(->it.path)
    for member in family =>
      tts = text-to-svg.load-sync member.path
      if metamap[member.path] and metamap[member.path].sample => text = metamap[member.path].sample
      else text = font.name
      d = tts.getD if (!member.style or member.style == \Regular) => text else "#{text} #{member.style}"
      if !d or is-rect(d) => continue
      member.d = d
      member.box = path-bounds(d)
    font.family-names = family.map(-> it.style).filter(->it)
    font.render-info = family
    if font.render-info and font.render-info.length => 
      font.render-sample = font.render-info.filter(->!it.style or it.style == \Regular).0 or font.render-info.0
      if !(font.render-sample.d and font.render-sample.box) => delete font.render-sample
      else if !(font.render-sample.box.width and font.render-sample.box.height) => delete font.render-sample
    if font.render-sample =>
      metadata = "#{path.dirname(font.render-sample.path)}/METADATA.pb"
      meta = metamap[font.render-sample.path]
      if fs.exists-sync metadata =>
        ret = /category: "([^"]+)"/.exec(fs.read-file-sync metadata .toString!)
        if ret => font.category = [ret.1]
      else if meta =>
        font.category = if meta.category => that else meta
        if !Array.isArray(font.category) => font.category = [font.category]
    return res!
  catch e
    return rej new Error(e)

process-fonts = (fonts) -> new Promise (res, rej) ->
  try
    idx = -1
    bar = progress-bar fonts.length, "vectorizing"
    _ = ->
      idx := idx + 1
      bar.tick!
      if idx >= fonts.length =>
        return res!
      font = fonts[idx]
      process-font font
        .then -> _!
        .catch -> _!
    _!
  catch e
    return rej new Error(e)

fs-extra.ensure-dir-sync \assets
console.log "build font sprite image...\n".cyan
fonthash = get-font-list \fonts
process-fonts [v for k,v of fonthash]
  .then ->
    fontlist = [v for k,v of fonthash].filter(->it.render-info and it.render-sample)
    fontlist.sort (a,b) -> if b.name > a.name => -1 else if b.name == a.name => 0 else 1
    console.log "   total #{fontlist.length} fonts vectorized.".green
    console.log "   composite sprite svg file...".cyan
    if !fontlist.length => return
    paths = []
    scale = scale-multiplier * Math.min.apply null, fontlist.map(->
      Math.min(
        dim.width / (dim.padding * 2 + it.render-sample.box.width),
        dim.height / (dim.padding * 2 + it.render-sample.box.height)
      )
    )
    for idx from 0 til fontlist.length =>
      font = fontlist[idx]
      {d, box} = font.render-sample{d, box}
      x = (idx % dim.col) * dim.width
      y = Math.floor(idx / dim.col) * dim.height
      cx = x - (box.x + box.width * 0.5) * scale + dim.width * 0.5
      cy = y - (box.y + box.height * 0.5) * scale + dim.height * 0.5
      sprite-rect = """
      <rect x="#x" y="#y" width="#{dim.width}" height="#{dim.height}" fill="none" stroke="black" stroke-width="2"/>
      """
      font-rect = """
      <rect x="#{box.x}" y="#{box.y}" width="#{box.width}" height="#{box.height}"
      fill="none" stroke="red" stroke-width="1"/>"""
      paths.push """
        #{if debug? => sprite-rect else ''}
        <g transform="translate(#cx #cy)">
          <g transform="scale(#scale)">
            #{if debug? => font-rect else ''}
            <path d="#{d}"/>
          </g>
        </g>
      """
    width = dim.col * dim.width
    height = Math.ceil(fontlist.length / dim.col) * dim.height
    svg = """
    <?xml version="1.0" encoding="utf-8"?>
    <svg xmlns="http://www.w3.org/2000/svg" width="#width" height="#height" viewBox="0 0 #width #height">
    #{paths.join('')}
    </svg>
    """
    fs.write-file-sync \assets/sprite.svg, svg
    meta = do
      dim: dim, fonts: fontlist.map -> {family: it.family-names} <<< it{name, category, is-set}
    console.log "   write meta data...".cyan
    fs.write-file-sync \assets/meta.json, JSON.stringify(meta)
    console.log "   convert sprite svg to png...".cyan
    #svg2png new Buffer(svg)
    svg2png Buffer.from(svg)
  .then (buf) ->
    new Promise (res, rej) ->
      fs.write-file-sync \assets/sprite.png, buf
      pq = new pngquant [8, '--quality', '40-50']
      console.log "   optimize sprite png file...".cyan
      ret = fs.createReadStream \assets/sprite.png
        .pipe pq
        .pipe fs.createWriteStream("assets/sprite.min.png")
      ret.on \finish, -> return res!
  .then -> console.log "   done.".green
  .catch -> console.log it
