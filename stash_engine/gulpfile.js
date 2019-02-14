// ##### Gulp Toolkit for the Dash UI Library #####

const { series, parallel, src, dest, watch } = require('gulp');

const assets = require('postcss-assets');
const autoprefixer = require('gulp-autoprefixer');
const browserSync = require('browser-sync');
const del = require('del');
const gulpIf = require('gulp-if');
const imagemin = require('gulp-imagemin');
const jshint = require('gulp-jshint');
const lbInclude = require('gulp-lb-include');
const minifyCSS = require('gulp-clean-css');
const modernizr = require('gulp-modernizr');
const postcss = require('gulp-postcss');
const sass = require('gulp-sass');
const scsslint = require('gulp-scss-lint');
const shell = require('gulp-shell');
const ssi = require('browsersync-ssi');
const sourcemaps = require('gulp-sourcemaps');
const uglify = require('gulp-uglify');
const useref = require('gulp-useref');
const validateHTML = require('gulp-w3cjs');

// ***** Plugins That Run a Single Process ***** //

// Run these processes from the command line using the task name. Example: $ gulp hello

// Check that gulp is working:
function helloTask(cb) {
  console.log('Gulp is installed and running correctly.');
  cb();
}

// copy font-awesome into fonts
function iconsTask(cb) {
  cb(
    src('./ui-library/bower_components/font-awesome/fonts/**.*')
      .pipe(dest('./ui-library/fonts'))
  );
};

// Minify all images during development:
function minifyImagesTask(cb) {
  cb(
    src('ui-library/images/**')
      .pipe(imagemin())
      .pipe(dest('ui-library/images'))
  );
};

// Run 'gulp modernizr' to build a custom modernizr file based off of classes found in CSS:
function modernizrTask(cb) {
  src('ui-library/css/main.css') // where modernizr will look for classes
    .pipe(modernizr({
      options: ['setClasses'],
      dest: 'ui-library/js/modernizr-custombuild.js'
    }));
  cb();
};

// Validate build HTML:
function validateHtmlTask(cb) {
  src('public/demo/**/*.html')
    .pipe(validateHTML());
  cb();
};

// ***** Plugins That Run As Part of a Combined Process ***** //

// These processes are run from the ones above.

// Process Sass to CSS, add sourcemaps, autoprefix CSS selectors, optionally Base64 font and image files into CSS, and reload browser:
function sassTask(cb) {
  src('ui-library/scss/**/*.scss')
    .pipe(sourcemaps.init())
    .pipe(sass.sync().on('error', sass.logError))
    .pipe(autoprefixer('last 2 versions'))
    .pipe(postcss([assets({
      loadPaths: ['fonts/', 'images/']
    })]))
    .pipe(sourcemaps.write('sourcemaps'))
    .pipe(dest('ui-library/css'))
    .pipe(browserSync.reload({
      stream: true
    }));
  cb();
};

// Watch sass, html, and js and reload browser if any changes:
function watchTask(cb) {
  parallel(browserSyncTask, sassTask, scssLintTask, jsLintTask);
  watch('ui-library/scss/**/*.scss', sassTask);
  watch('ui-library/scss/**/*.scss', scssLintTask);
  watch('ui-library/js/**/*.js', jsLintTask);
  watch('ui-library/**/*.html', browserSync.reload);
  watch('ui-library/js/**/*.js', browserSync.reload);
};


// Spin up a local browser with the index.html page at http://localhost:3000/
function browserSyncTask(cb) {
  browserSync({
    server: {
      baseDir: 'ui-library',
      middleware: ssi({
        baseDir: __dirname + '/ui-library',
        ext: '.html',
        version: '1.4.0'
      })
    },
  });
  cb();
};

// Concatenate and minify CSS and JavaScript from paths within useref tags during build process; include files:
function userefTask(cb) {
  cb(
    src(['ui-library/**/*.html', '!ui-library/includes/*'])
      .pipe(useref())
      // commenting out minify and uglify since asset pipeline will do this and makes it easier to troubleshoot without
      // .pipe(gulpIf('*.css', minifyCSS()))
      // .pipe(gulpIf('*.js', uglify()))
      .pipe(lbInclude()) // Process <!--#include file="" --> statements
      .pipe(dest('public/demo'))
  );
};

// Delete 'demo' directory at start of build process:
function cleanTask(cb) {
  cb(del('public/demo'));
};

// Copy images to demo directory during the build process:
function copyImagesTask(cb) {
  cb(
    src('ui-library/images/**')
      .pipe(dest('public/demo/images'))
  );
};

// Copy fonts to demo directory during the build process:
function copyFontsTask(cb) {
  cb(
    src('ui-library/fonts/**')
      .pipe(dest('public/demo/fonts'))
  );
};

// Copy the single CSS and JS files from UI library build to Rails asset pipeline:
function copyToAssetsTask(cb) {
  shell.task([
    'cp public/demo/css/ui.css app/assets/stylesheets/stash_engine',
    'cp public/demo/js/ui.js app/assets/javascripts/stash_engine'
  ]);
  cb();
};

// Lint Sass:
function scssLintTask(cb) {
  cb(
    src(['ui-library/scss/**/*.scss', '!ui-library/scss/vendor/**/*.scss'])
      .pipe(scsslint({
        'config': 'scss-lint-config.yml' // Settings for the linter. See: https://github.com/brigade/scss-lint/tree/master/lib/scss_lint/linter
      }))
  );
};

// Lint JavaScript:
function jsLintTask(cb) {
  cb(
    src(['ui-library/js/**/*.js', '!ui-library/js/modernizr-custombuild.js'])
      .pipe(jshint())
      .pipe(jshint.reporter('default'))
  );
};

function buildTask(cb) {
  series(
    cleanTask,
    [scssLintTask, jsLintTask, sassTask, userefTask, iconsTask, copyImagesTask, copyFontsTask],
    copyToAssetsTask
  );
  cb();
};


// Commands available via the command line. For example: `gulp hello`
exports.hello = helloTask;
exports.minifyImages = minifyImagesTask;
exports.modernizr = modernizrTask;
exports.build = buildTask;
exports.validateHTML = validateHtmlTask;

// Setup the default to run gulp in dev mode so that its watching our files
exports.default = series(sassTask, browserSyncTask, watchTask);