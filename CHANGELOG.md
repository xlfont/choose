# Change Logs

## v0.0.13 (upcoming)

 - remove svg2png to fix vulnerability


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
