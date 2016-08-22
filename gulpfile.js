// ##### Gulp Toolkit for the Dash UI Library #####

var gulp = require('gulp');
var sass = require('gulp-sass');
var autoprefixer = require('gulp-autoprefixer');
var sourcemaps = require('gulp-sourcemaps');
var browserSync = require('browser-sync');
var useref = require('gulp-useref');
var uglify = require('gulp-uglify');
var gulpIf = require('gulp-if');
var minifyCSS = require('gulp-clean-css');
var imagemin = require('gulp-imagemin');
var del = require('del');
var modernizr = require('gulp-modernizr');
var runSequence = require('run-sequence');
var validateHTML = require('gulp-w3cjs');
var scsslint = require('gulp-scss-lint');
var jshint = require('gulp-jshint');
var lbInclude = require('gulp-lb-include');
var ssi = require('browsersync-ssi');
var postcss = require('gulp-postcss');
var assets = require('postcss-assets');
var shell = require('gulp-shell')


// ***** Plugins That Run a Single Process ***** //

// Run these processes from the command line using the task name. Example: $ gulp hello 


// Check that gulp is working:
gulp.task('hello', function() {
  console.log('Gulp is installed and running correctly.');
});


// Run the dev process 'gulp':
gulp.task('default', function (callback) {
  runSequence(['sass', 'browserSync', 'watch'],
    callback
  )
})


// Run the build process 'build':
gulp.task('build', function (callback) {
  runSequence('clean', 
    ['scss-lint', 'js-lint', 'sass', 'useref', 'copy-images'], 'copy-to-assets',
    callback
  )
})


// Minify all images during development:
gulp.task('minify-images', function(){
  return gulp.src('ui-library/images/**')
  .pipe(imagemin())
  .pipe(gulp.dest('ui-library/images'))
});


// Run 'gulp modernizr' to build a custom modernizr file based off of classes found in CSS:
gulp.task('modernizr', function() {
  gulp.src('ui-library/css/main.css') // where modernizr will look for classes
    .pipe(modernizr({
      options: ['setClasses'],
      dest: 'ui-library/js/modernizr-custombuild.js'
    }))
});


// Validate build HTML:
gulp.task('validateHTML', function () {
  gulp.src('public/demo/**/*.html')
    .pipe(validateHTML())
});


// ***** Plugins That Run As Part of a Combined Process ***** //

// These processes are run from the ones above.


// Process Sass to CSS, add sourcemaps, autoprefix CSS selectors, optionally Base64 font and image files into CSS, and reload browser:
gulp.task('sass', function() {
  return gulp.src('ui-library/scss/**/*.scss')
    .pipe(sourcemaps.init())
    .pipe(sass.sync().on('error', sass.logError))
    .pipe(autoprefixer('last 2 versions'))
    .pipe(postcss([assets({
      loadPaths: ['fonts/', 'images/']
    })]))
    .pipe(sourcemaps.write('sourcemaps'))
    .pipe(gulp.dest('ui-library/css'))
    .pipe(browserSync.reload({
      stream: true
    }));
})


// Watch sass, html, and js and reload browser if any changes:
gulp.task('watch', ['browserSync', 'sass', 'scss-lint', 'js-lint'], function (){
  gulp.watch('ui-library/scss/**/*.scss', ['sass']);
  gulp.watch('ui-library/scss/**/*.scss', ['scss-lint']);
  gulp.watch('ui-library/js/**/*.js', ['js-lint']);
  gulp.watch('ui-library/**/*.html', browserSync.reload); 
  gulp.watch('ui-library/js/**/*.js', browserSync.reload); 
});


// Spin up a local browser with the index.html page at http://localhost:3000/
gulp.task('browserSync', function() {
  browserSync({
    server: {
      baseDir: 'ui-library',
      middleware: ssi({
        baseDir: __dirname + '/ui-library',
        ext: '.html',
        version: '1.4.0'
      })
    },
  })
})


// Concatenate and minify CSS and JavaScript from paths within useref tags during build process; include files:
gulp.task('useref', function(){
  return gulp.src(['ui-library/**/*.html', '!ui-library/includes/*'])
    .pipe(useref())
    // commenting out minify and uglify since asset pipeline will do this and makes it easier to troubleshoot without
    // .pipe(gulpIf('*.css', minifyCSS()))
    // .pipe(gulpIf('*.js', uglify()))
    .pipe(lbInclude()) // Process <!--#include file="" --> statements
    .pipe(gulp.dest('public/demo'))
});


// Delete 'demo' directory at start of build process:
gulp.task('clean', function() {
  return del('public/demo');
})


// Copy images to demo directory during the build process:
gulp.task('copy-images', function(){
  return gulp.src('ui-library/images/**')
  .pipe(gulp.dest('public/demo/images'))
});


// Copy the single CSS and JS files from UI library build to Rails asset pipeline:
gulp.task('copy-to-assets', shell.task([
  'cp public/demo/css/ui.css app/assets/stylesheets/stash_engine',
  'cp public/demo/js/ui.js app/assets/javascripts/stash_engine'
]))


// Lint Sass:
gulp.task('scss-lint', function() {
  return gulp.src(['ui-library/scss/**/*.scss', '!ui-library/scss/vendor/**/*.scss'])
    .pipe(scsslint({
      'config': 'scss-lint-config.yml' // Settings for the linter. See: https://github.com/brigade/scss-lint/tree/master/lib/scss_lint/linter
    }));
});


// Lint JavaScript:
gulp.task('js-lint', function() {
  return gulp.src(['ui-library/js/**/*.js', '!ui-library/js/modernizr-custombuild.js'])
    .pipe(jshint())
    .pipe(jshint.reporter('default'))
});
