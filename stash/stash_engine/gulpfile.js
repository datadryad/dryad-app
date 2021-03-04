// ##### Gulp Toolkit for the Dash UI Library #####

const { series, parallel, src, dest, watch } = require('gulp');

const assets = require('postcss-assets');
const autoprefixer = require('gulp-autoprefixer');
const browserSync = require('browser-sync').create();
const del = require('del');
const gulpIf = require('gulp-if');
const imagemin = require('gulp-imagemin');
const jshint = require('gulp-jshint');
const lbInclude = require('gulp-lb-include');
const modernizr = require('gulp-modernizr');
const postcss = require('gulp-postcss');
const sass = require('gulp-sass');
const shell = require('gulp-shell');
const ssi = require('browsersync-ssi');
const sourcemaps = require('gulp-sourcemaps');
const stylelint = require('gulp-stylelint');
const useref = require('gulp-useref');
const validateHTML = require('gulp-w3cjs');
const { spawn } = require('child_process');

// ***** Plugins That Run a Single Process ***** //

// Run these processes from the command line using the task name. Example: $ gulp hello

// Check that gulp is working:
function helloTask(cb) {
  console.log('Gulp is installed and running correctly.');
  cb();
}

function copyPackageFilesTask() {
  return spawn('npm run copy-pkg-files --silent', {
    stdio: 'inherit',
    shell: true,
  });
};

// copy font-awesome into fonts
function iconsTask(cb) {
  return src('./ui-library/bower_components/font-awesome/fonts/**.*')
    .pipe(dest('./ui-library/fonts'));
};

// Minify all images during development:
function minifyImagesTask(cb) {
  return src('ui-library/images/**')
    .pipe(imagemin())
    .pipe(dest('ui-library/images'));
};

// Run 'gulp modernizr' to build a custom modernizr file based off of classes found in CSS:
function modernizrTask(cb) {
  return src('ui-library/css/main.css') // where modernizr will look for classes
    .pipe(modernizr({
      options: ['setClasses'],
      dest: 'ui-library/js/modernizr-custombuild.js'
    }));
};

// Validate build HTML:
function validateHtmlTask(cb) {
  return src('dist/**/*.html')
    .pipe(validateHTML());
};

// ***** Plugins That Run As Part of a Combined Process ***** //

// These processes are run from the ones above.

// Process Sass to CSS, add sourcemaps, autoprefix CSS selectors, optionally Base64 font and image files into CSS, and reload browser:
function sassTask(cb) {
  return src('ui-library/scss/**/*.scss')
    .pipe(sourcemaps.init())
    .pipe(sass.sync().on('error', sass.logError))
    .pipe(autoprefixer('last 2 versions'))
    .pipe(postcss([assets({
      loadPaths: ['fonts/', 'images/']
    })]))
    .pipe(sourcemaps.write('sourcemaps'))
    .pipe(dest('ui-library/css'))
    .pipe(browserSync.stream());
};

// Watch sass, html, and js and reload browser if any changes:
function watchTask(cb) {
  watch('ui-library/scss/**/*.scss', sassTask);
  watch('ui-library/scss/**/*.scss', scssLintTask);
  watch('ui-library/js/**/*.js', jsLintTask);
  watch('ui-library/**/*.html').on('change', browserSync.reload);
  watch('ui-library/js/**/*.js').on('change', browserSync.reload);
};


// Spin up a local browser with the index.html page at http://localhost:3000/
function browserSyncTask(cb) {
  return browserSync.init({
    server: {
      baseDir: 'ui-library',
      middleware: ssi({
        baseDir: __dirname + '/ui-library',
        ext: '.html',
        version: '1.4.0'
      })
    },
  });
};

// Copy HTML files to /dist folder, add 'include' files, concatenate CSS and JavaScript from paths within useref tags:
function userefTask(cb) {
  return src(['ui-library/**/*.html', '!ui-library/includes/*'])
    .pipe(lbInclude()) // Process <!--#include file="" --> statements
    .pipe(useref())
    .pipe(dest('dist'))
};

// Delete dist directory at start of build process:
function cleanTask(cb) {
  return del('dist');
};

// Copy images to dist directory during the build process:
function copyImagesTask(cb) {
  return src('ui-library/images/**')
    .pipe(dest('dist/images'));
};

// Copy fonts to dist directory during the build process:
function copyFontsTask(cb) {
  return src('ui-library/fonts/**')
    .pipe(dest('dist/fonts'));
};

// Copy the single CSS and JS files from UI library build to Rails asset pipeline:
function copyToAssetsTask(cb) {
  return src('dist/', { read: false })
    .pipe(shell([
      'cp dist/css/ui.css app/assets/stylesheets/stash_engine',
      'cp dist/js/ui.js app/assets/javascripts/stash_engine']));
/*
  shell.task([
    'cp public/demo/css/ui.css app/assets/stylesheets/stash_engine',
    'cp public/demo/js/ui.js app/assets/javascripts/stash_engine'
  ], cb);
*/
};

// Lint Sass:
function scssLintTask(cb) {
  return src(['ui-library/scss/**/*.scss', '!ui-library/scss/vendor/**/*.scss'])
    .pipe(stylelint({
    reporters: [
      {formatter: 'string', console: true}
    ]
  }));
};

// Lint JavaScript:
function jsLintTask(cb) {
  return src(['ui-library/js/**/*.js', '!ui-library/js/modernizr-custombuild.js', '!ui-library/js/vendor/**/*.js'])
    .pipe(jshint())
    .pipe(jshint.reporter('default'));
};

function publishTask() {
  return spawn('NODE_DEBUG=gh-pages npm run publish', {
    stdio: 'inherit',
    shell: true,
  });
};

// Commands available via the command line. For example: `gulp hello`
exports.hello = helloTask;
exports.copyPackageFiles = copyPackageFilesTask;
exports.minifyImages = minifyImagesTask;
exports.modernizr = modernizrTask;
exports.validateHTML = validateHtmlTask;

// Standard build that should be run before deploying the application
exports.build = series(cleanTask, copyPackageFilesTask, scssLintTask, jsLintTask, sassTask, userefTask, iconsTask,
                       copyImagesTask, copyFontsTask, copyToAssetsTask);

// Publish a build to GitHub Pages
exports.publish = series(cleanTask, copyPackageFilesTask, scssLintTask, jsLintTask, sassTask, userefTask, iconsTask, copyImagesTask, copyFontsTask, publishTask);

// Setup the default to run gulp in dev mode so that its watching our files
exports.default = parallel(copyPackageFilesTask, sassTask, browserSyncTask, watchTask);
