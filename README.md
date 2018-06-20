Choosefont.js
==============

Resource packer and widget for super fast in-browser font picking experience.


Build Resource
--------------

1. prepare your font files under ```fonts``` directory.
    1. choosefont will traverse and find all ttf files automatically. 
    2. font named after its filename.
    3. use METADATA.pb in the same folder for category. ( check google-fonts for example.
    4. use meta.json in root directory for additional font information ( check meta.json in this repo for example)
2. execute following:

    lsc main

3. following files are generated under ```assets``` directory:
    1. a font meta json ( ```meta.json``` ), 
    2. a minimized png sprite ( ```sprite.min.png``` )
    3. non-minimzed png and svg file


Use Choosefont.js
---------------

init choosefont.js with following command:

    var chooser = choosefont.init(
      container, /* root element for the chooser widget */
      5, /* how many fonts in a row */
      "path-to-meta-json" /* url of generated  meta.json */
    )


and filtering the chooser via following command:

    chooser.filter({
      name: "<keyword-for-font-name>"
      category: "<category>"
    })
    

to restore unfiltered status, just pass nothing into it:

    chooser.filter();
    

watch for events:

    chooser.on("choose", function(font) {
      /* font is loaded. just use font object */
    });
    
You will find following attribute in the font object:

 * name - font name.
 * isSet - is a subsetted font.
 * category - list of category for this font
 * family - possible variant of this font.


Following is an example of using xl-fontload+ Choosefont.js:

    chooser.on("choose", function(font) {
      xfl.load("path-to-my-fontdir/", font, function(font) {
        document.body.style.fontFamily = font.name;
      });
    })


LICENSE
============

MIT License.

