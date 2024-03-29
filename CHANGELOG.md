# Change Logs

## v0.0.29

 - clone metadata locally to prevent pollute source object


## v0.0.28

 - support `metadata(m)` api for manually provide metadata and skip ajax completely


## v0.0.27

 - update document
 - add `file` and `limit` in font object `mod` field for tracking uploaded file
 - support loading by uploaded font (with blob provided)
 - move code for preparing for uploaded font into separated function to support
   both font uploading from user interaction and from chooser.load function call.


## v0.0.26

 - use font name instead of font object to match font in meta font list.


## v0.0.25

 - remove unused log


## v0.0.24

 - correctly support limit flag.


## v0.0.23

 - add `apache2` license fonts


## v0.0.22

 - add `config` method
 - `render` now returns Promise
 - make option `upload` a function


## v0.0.21

 - tweak upload button label
 - prevent upload button wrapping
 - tweak font list style
 - enforce init before rendering
 - support font sorting
 - support limitation in upload and font choosing


## v0.0.20

 - support custom uploaded font file


## v0.0.19

 - ignore empty object in meta.json, while still keeping their index to correctly match thumbnails in sprite file.


## v0.0.18

 - support searching


## v0.0.17

 - upgrade dependencies for vulnerabilities fixing
 - support API for fallback URL for font files.
 - tweak css for font preview item to prevent hover glitching


## v0.0.16

 - init dropdown if `BSN` is available


## v0.0.15

 - return null when load font with null provided as parameter


## v0.0.14

 - support font loading with simplified font object.


## v0.0.13

 - remove svg2png to fix vulnerability
 - support lazy init until load
 - support load with font name
 - support headless mode
 - upgrade modules


## v0.0.12

 - show loading indicator when rendering the chooser ui
 - add `style` in `package.json`
 - add `main` and `browser` field in `package.json`.
 - further minimize generated js file with mangling and compression
 - upgrade modules
 - patch test code to make it work with upgraded modules
 - release with compact directory structure


## v0.0.11

 - show loading indicator when font is choosed and loading
 - upgrade modules


## v0.0.10

 - fix constructor option typo
 - convert index values to lower case
 - upgrade vscroll for better scrolling experience
 - use xlfont.maketext.io as font repo


## v0.0.9

 - support config file
 - support ignores option in config file mode
 - add sample config and test fonts in `tool/sample`


## v0.0.8

 - remove fonts that isn't open licensed.
   - this should be designed as configurable in future release


## v0.0.7

 - check path[0] for existency before pushing


## v0.0.6

 - add missing files in previous release


## v0.0.5

 - use sample text in METADATA.pb to render
 - add some additional sample text for code plane


## v0.0.4

 - use sharp to generate png files
 - also generate webp file ( note webp has dimension limitation )


## v0.0.3

 - tweak constructor option naming
 - ugprade dev modules and use vscroll in demo page
 - support `initRender` option
 - add `render` function


## v0.0.2

 - fix null font bug
 - ignore unrecognized METADAT.pb format for now.


## v0.0.1

 - migrate from `choosefont.js`
 - refactor everything
 - rename package, re-versioning from 0.0.1
