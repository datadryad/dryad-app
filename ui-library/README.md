# Dash UI Library

A Library of static objects, components, and themes that make up the Stash application user interface.

## Library Toolkit

The Dash UI Library is located within **/ui-library** at this project's root directory. It is developed with a
[Gulp](http://gulpjs.com)-based toolkit included with the Stash application. Like most build tools, it processes styles
and scripts, creates and deploys finished builds, live-reloads file changes, and runs other optimization tasks. 

You are welcome to use any build tool to do these tasks. However, you are encouraged to use the Gulp toolkit included
with this UI library, as it is already configured to the Stash application and copies files directly to the Rails asset
pipeline.

### Toolkit Requirements

* [Node and npm](https://nodejs.org/en) Node needs to be installed. 

  For Mac OS users with Homebrew, note that the Homebrew `node`/`npm`
  installation has issues. Use the `.pkg` installer from
  [nodejs.org](https://nodejs.org/en/download/), and afterwards add
  `$HOME/.npm-packages/bin` to your `$PATH`.

* [Bower](https://bower.io): `$ sudo npm install -g bower`

* [Gulp](https://github.com/gulpjs/gulp/blob/master/docs/getting-started.md): `$ sudo npm install -g gulp-cli`

### Toolkit Installation

1. Clone this repo and cd to its root directory on your machine

2. Run `$ npm install` to install Gulp plugins. Ignore the various "depreciated" warnings that appear.

3. Run `$ bower install` to install Bower libraries

### Running the Toolkit

* Cd to this repo's root directory

* Run `$ gulp hello` to confirm that the Gulp toolkit is installed

* While developing files in **/ui-library**, run `$ gulp` to watch
  live changes at http://localhost:3000

* To minify images during development, run `$ gulp minify-images` after adding new, unoptimized images

* To update the custom modernizr file based off of classes found in CSS, run `$ gulp modernizr` after introducing new
CSS features referenced in the [Modernizr development build](https://modernizr.com)

* To create a build of finished files and copy the compiled CSS and JavaScript files into the 
  Rails asset pipeline, run `$ gulp build`

* To validate HTML of a build using the W3C validation service, run `$ gulp validateHTML`

* To publish the UI Library online for peer review, run `$ gulp publish` (GitHub Pages must be enabled within GitHub). The public URL is: https://cdl-dryad.github.io/dryad-app

## Project Structure

**/ui-library**: The **ui-library** directory is where development takes place. Builds of finished files are
placed within **ui-library/dist** by the Gulp toolkit.

**/bower\_components**: [Bower](https://bower.io) libraries are not located at the project root, as tyically done, but
in **ui-library/bower_components** so that the Gulp toolkit can serve and optimize them.

**/fonts**: Font files are located in **ui-library/fonts** and are inlined into the **ui-library** and **dist** CSS
files by the Gulp toolkit. See the *Styles* section below for how to run this task in the toolkit.

**/images**: Image files are located at **ui-library/images** and **dist/images**. Files prepended with **icon_** are
typically inlined into the CSS files using the same Gulp toolkit process as the font files mentioned above.

**/includes**: Includes contain the actual UI elements. They are located at **ui-library/includes** and are compiled
into the object, component, and theme files within the **dist** directory during the build process. Their organization
is described in the *UI Elements* section below.

**/scss**: Styles are written in multiple [Sass](http://sass-lang.com) files within **ui-library/scss**. They are
compiled to **ui-library/css/main.css** during development runtime and a minified **dist/css/ui.css** for during the
build process. Both the **main.css** and **ui.css** files should not be modified, as they will be overwritten with new
versions as the Gulp toolkit is run. For style authoring patterns and best practices, please see the *Styles* section below.

**/js**: JavaScript files exist in **ui-library/js** and get compiled to **dist/js/ui.js** during the build process.
The main JavaScript file at **ui-library/js/main.js** is mostly for basic DOM manipulation of HTML attributes,
typically using jQuery. Two other custom JS files, **details-polyfill.js** and **modernizr-custombuild.js**
exist within **ui-library/js** and get concatenated into **ui.js** for builds. Like the CSS files mentioned above,
you should not modify **ui.js** in the **dist** directory, as it will be overwritten during each build.

## UI Elements

UI elements are typically organized from the smallest part (Objects) that make up larger structures (Components), which
are assembled at the page level (Themes). This hierarchy is similar to
the [Atomic Design model](http://bradfrost.com/blog/post/atomic-web-design).

Each UI element has a separate 'display' page so that it can render as a standalone item on a single page. These are
prepended with **object\_** for Object pages, **component\_** for Component pages, and **theme\_** for Theme pages.

Each **ui-library/include** file contains the actual element, component, or layout code - this is where you develop the
elements. Especially for the theme pages within **ui-library**, multiple *include* files are present in the code to set
the layout.

## Styles

The Sass in this UI library follows [this style guide](https://css-tricks.com/sass-style-guide). The Gulp toolkit's
Sass linter honors most of these rules and will throw warnings if there are exceptions.

Each Object, Component, and Theme has its own Sass partial, which are all imported into **ui-library/scss/main.scss**
and then compiled into the **ui-library** and **dist** CSS files.

The **main.scss** file also imports global Sass variables, mixins, fonts, resets, and a Bower library. Opening these
files and glancing at the code can help you see how the styles are organized across the UI library.

CSS selectors in the Sass partials are written using the [BEM naming convention](https://css-tricks.com/bem-101) with
a modified form of [namespacing](http://csswizardry.com/2015/03/more-transparent-ui-code-with-namespaces).

The namespaces in this UI library designate if a class is an object, component, theme, or for only binding JavaScript
by using the prefixed letter **o-**, **c-**, **t-**, or **js-**. Theme classes are meant to be used sparingly, mostly
for just aligning object and component alignment within the Theme pages.

Selector blocks are typically named after the scss filename they belong to. For example, the Banner Object's styles are
located in `_banner.scss` and the selector block is named **o-banner**.

When media queries are included in a style declaration, they are written 'mobile-first'. The selector's properties
first define the small screen experience, then a media query for the bigger screen experience is added with properties
that add upon or override the small screen properties. To see how media queries are used throughout the UI library,
open the file, **ui-library/scss/_mixins.scss** to see examples in the Sass code.

In the UI element HTML, two or more classes with different namespaces will sometimes be chained together into an HTML's
class attribute. For example, `class="t-describe__locations c-locations"`. This is to add *complementary* styles to a
DOM object, not to cancel or reset styles between the classes.

Image and font files are inlined as Base64 into the CSS to eliminate the paths to these assets and reduce HTTP requests
for better performance. To do this, change a CSS selector's `url` value to `inline` while running `gulp`. [More about
inlining files with PostCSS Assets](https://github.com/assetsjs/postcss-assets#inlining-files)

CSS properties should not be prefixed, as this is done automatically via the Gulp toolkit's
[Autoprefixer](https://www.npmjs.com/package/gulp-autoprefixer).

## Scripts

The JavaScript authored in this library takes place in one file, **ui-library/js/main.js** and mostly performs basic
DOM changes using jQuery. When classes or IDs are used to target the DOM, they are typically prefixed with
the **-js** namespace, as mentioned above.

Styles are kept out of these classes prefixed with **-js**, only JavaScript binding is used. This is to honor a
separation of concerns and avoid style/script conflicts. When styles and scripts are needed together on a UI element,
their classes are chained together in the HTML class attribute, like `class="js-widget c-widget"`.

### UI vs Application JavaScript

Some JavaScript in the Stash application is more "UI" focused, while other scripts focus more on "application" logic.
For elements in the UI library that require simple UI interactivity (like show/hide on click), it is recommended that
JavaScript for them be written within the UI library's **ui-library/js** file. Scripts that focus on application logic
are better kept as separate entities outside of the UI library. This is to ensure that the UI-based JavaScript can
function independently of the application business logic without breaking the logic-directed scripting in the Stash
application.

## Integrating UI Library Code into Dash Application

All UI-based HTML, CSS, and JavaScript for the Stash application is created and modified within this UI library and
then integrated into the Dash application as a one-way process. If possible, avoid writing separate HTML, CSS, and JS
outside of the UI library, directly in the Dash application. Maintaining a best practice of authoring these files
within the UI library will ensure that there are no UI conflicts between the UI library and Stash application.

Here is the typical authoring and integration process:

1. Create or modify an element within the **ui-library** directory while running the Gulp toolkit. Keep your code
organized and coherent by following the Style guidelines mentioned above.

2. Run a build from the Gulp toolkit. The the **main.css** and **ui.css** files from the build are automatically copied
to the Rails asset pipeline in **app/assets**.

3. Optionally, validate your build HTML via the Gulp toolkit.

4. Review your build from the local Rails server on your machine at **dist**. 
**Note:** the trailing slash is required; otherwise you'll just get the unstyled static pages.

5. Integrate the HTML of the elements you created or modified within the UI library into the same elements in Rails.

6. From your local Rails server, verify that the styles and JS functionality you integrated in Rails render exactly
as they do from the UI library. If not, use the browser's Inspector tool and double-check that Rails is outputting HTML
that matches what's in the UI library.

7. Check accessibility of the Rails output using the [Wave tool on Chrome](http://wave.webaim.org/extension),
especially if you are rendering form elements on a page.

8. If all looks good, commit your changes.
