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
    script: include:lsc
      chooser = new xfc do
        root: '.ldcv'

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


## Build 

1. prepare your font files under ```tool/fonts``` directory.
    1. choosefont will traverse and find all ttf files automatically.
    2. font named after its filename.
    3. use METADATA.pb in the same folder for category. ( check google-fonts for example.
    4. use meta.json in root directory for additional font information ( check meta.json in this repo for example)
    5. for any font in the xl-fontset format, you can put a symlink to it as ```fontset``` directory under tool/.
2. execute following:

    lsc main

3. following files are generated under ```assets``` directory:
    1. a font meta json ( ```meta.json``` ),
    2. a minimized png sprite ( ```sprite.min.png``` )
    3. non-minimzed png and svg file


## Use Choosefont.js

xfl.js is required. include it at first.

then make a font chooser with following:

```
    var chooser = new ChooseFont(config);
    chooser.init();
```

Configurations:

 * root: root element for ChooseFont.
 * meta-url: URL for your meta.json.
 * base: URL for where to find all your fonts.
 * disable-filter(font, idx): filter function to decide whether to disable specific font. return true or false.
 * default-filter(font, idx): filter functino to decide whether to show specific font at all. return true or false.
 * type: type of chooser. either 'grid' or 'list'. default 'grid'.
 * itemClass: add additional classes to font list item. should be space separated string.
 * cols: how many item per line ( for grid view ). default 4.
 * disable-filter(f, idx) - if you want to disable some font, return true when f / idx matches the font.
   - f object:
     category: [ ... ] # e.g., HANDWRITING
     family: [...] # e.g., Regular
     name: "fontName"
 * default-filter(f, idx) - if you want to disable some font, return true when f / idx matches the font.
   - same f object as disable-filter.

Once created, you can interact with chooser programmatically with following methods:

 * filter: filter list by name or category. input: object, such as {name: "Abel", category: "Display"}.
   - example:
     ```
     chooser.filter({
       name: "<keyword-for-font-name>"
       category: "<category>"
     })
     ```
   - clear filter by passing nothing:
     ```
     chooser.filter();
     ```

For reading user's feedback, you can watching for specific events with ```choose.on('event-name', handler)```. Following are available events:

 * choose: fire when user choose an event. return font object.
   - example:
     ```
     chooser.on("choose", function(font) {
       /* font is loaded. just use font object */
     });
     ```
   - font object contains following members:
     * name - font name.
     * isSet - is a subsetted font.
     * category - list of category for this font
     * family - possible variant of this font.

   - Following is an example of using xl-fontload+ Choosefont.js:
     ```
     chooser.on("choose", function(font) {
       xfl.load("path-to-my-fontdir/", font, function(font) {
         document.body.style.fontFamily = font.name;
       });
     })
     ```


## DOM Structure

```
  .choosefont
    .choosefont-head     ( only if provided manually )
    .choosefont-content  ( will be added automatically if none )
```


## LICENSE

MIT License.

