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
 - `meta`: metadata URL root
 - `links`: font file URL root
 - `i18n`: i18n object in `i18next` spec.
 - `initRender`: default false. when false, list should be rendered by calling `render` function manually.
   - font list rendering involves bounding box calculation, which may not be available when container isnt' visible.
   - in this case, user should manually call `render()` after container is visible.


## API

 - `render()`: render font list.


## Events

 - `choose`: fired when a font is chosen, with an xlfont object from `@xlfont/load` for the chosen font.


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

 - `--link`: output directory for symbolic links to font. default `./output/links`.
 - `--output`: output directory for metadata. default `./output/meta`.
 - `--font-size`: default font size. default 48, auto shrink if needed.

For a complete list of possible options, please run `npx xfc --help` directly.


## LICENSE

MIT License.

