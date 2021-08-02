# meta.json spec

meta.json stores an object with `family`, `index` and `dim` member objects:

 - `family`: array of font family objects.
 - `index`: index for following values:
   - `category`: Array of categories ( serif, sans serif, handwriting, display, monospace )
   - `style`: Array of styles ( normal, italic, etc )
   - `subsets`: Array of subsets ( cjk, latin, etc )
   - `weight`: Array of weight ( 100, 200, etc )
 - `dim`: dimension information of the preview sprite image.
   - `width`: width of preview region for one font
   - `height`: height of preview region for one font
   - `col`: how many fonts in a row. fonts are rendered as the order in `family` list.
   - `padding`: padding between fonts



## font family object

Each font family object contains following fields:

 - `n`: font family name
 - `c`: category (indexed)
 - `s`: subset (indexed)
 - `f`: Array of subfamilies:
   - `w`: font weight
   - `s`: font style (indexed)
   - `x`: true if this is an xlfont.

