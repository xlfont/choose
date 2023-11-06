# @xlfont/choose

font chooser including

 - ui and library for chooser dynamics
 - tool for building meta files from fonts of your choice.


## Frontend Usage

`@xlfont/choose` depends on `@xlfont/load` so you have to install both. Install by

    npm install --save @xlfont/choose @xlfont/load

and include `index.js` and `index.css` under `@xlfont/choose`'s `dist` folder, along with `index.js` in `@xlfont/load`.

HTML counterpart is also needed, which is available as a mixin in `dist/index.pug`, in `pug` format. `@xlfont/choose` is based on `ldview` which means UI / Logic is separated thus you can make your own chooser widget to fit your design ( while the JS Selectors are not documented so you have to check `index.pug` for reference. )

After installed, create a `xfc` instance:

    chooser = new xfc( ... )

Here is a minimal working example in `pug`, with `@plotdb/srcbuild` pug extension syntax:

    include @/@xlfont/choose/dist/index.pug
    .ldcv: +xfc
    script
      chooser = new xfc { root: '.ldcv', initRender: true }
      chooser.init!then -> ...


Check `web/src/pug/index.pug` for example with `ldcover` and `@xlfont/choose`.


## Constructor Options

 - `root`: container element or selector for inserting font chooser
 - `meta`: metadata URL root. fallback to url set by `xfc.url` if omitted.
 - `links`: font file URL root. fallback to url set by `xfc.url` if omitted.
 - `i18n`: i18n object in `i18next` spec.
 - `initRender`: default false. when false, list should be rendered by calling `render` function manually.
   - font list rendering involves bounding box calculation, which may not be available when container isnt' visible.
   - in this case, user should manually call `render()` after container is visible.
 - `order(a,b)`: sort font list based on given font objects where:
   - `n`: font name
 - `upload`: an object containing following flags:
   - `limited`: upload functionality is limited
 - `state({font, type})`: optional. return state of font for certain type.
   - type can be either:
     - `limited`: return true if this font is limited. default `limited` when `type` is omitted.
   - if implemented, should return `undefined` for unsupported `type`.


## API

 - `config(opt)`: update config, including `state` and `upload` option in constructor parameters.
 - `render()`: render font list.
 - `load(opt)`: load a font based on the given parameter `opt`.
   - returns a Promise which resolves with the desired font, or rejects if font is not found.
   - `opt` can be either:
     - a number: return the font by the given index from the font family list.
     - a string: return the font with the exact same name to `opt`, case insensitive.
     - a simplified font object such as `{name, style, weight}`
     - the font family object itself


## Class API

 - `url(opt)`: set url hint for meta and links urls
   - `opt` is an object with following fields:
     - `meta`: suggested metadata URL root
     - `links`: suggested font file URL root
   - when `opt` is omitted, return url hint or `{}` if not available.


## Events

 - `choose`: fired when a font is chosen, with an xlfont object from `@xlfont/load` for the chosen font.
 - `load.start`: fired when a font is loading. ( after user clicking a font )
 - `load.end`: fired when a font load ended. ( either succeeded or failed )
 - `load.fail`: fired when a font is failed to load.


## Metadata Generation

To generate metadata, also install `@xlfont/choose` if not installed yet:

    npm install --save-dev @xlfont/choose

A command (via npx) will be available after install:

    npx xfc

This command generates necessary files for `@xlfont/choose` to list your fonts. It generates:

 - a minimized PNG for previewing fonts.
 - metadata for font information, including name, style and position in previewer PNG.
 - a directory structure recgonized by `@xlfont/choose`, with symbolic links to the fonts your provided.

Avilable options:

 - `--link`: or `-l`, output directory for symbolic links to font. default `./output/links`.
 - `--output`: or `-m`, output directory for metadata. default `./output/meta`.
 - `--font-size`: or `-f`, default font size. default 48, auto shrink if needed.

For a complete list of possible options, please run `npx xfc --help` directly.


### Generate  with Configurations

You can also generate metadata with a prepared configuration file with `--config` or `-c` option. Supported fields in this configuration file are as follow:

 - `width`: default 400, width of font preview box
 - `height`: default 50, height of font preview box
 - `col`: default 5,
 - `padding`: default 10,
 - `fsize`: default 48,
 - `links`: output directory for symboic links to font.
 - `meta`: output directory for metadata.
 - `src`: source directory for source fonts.
 - `ignores`: a list of regular expressions for font names to exclude.


## LICENSE

MIT License.

