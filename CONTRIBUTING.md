# Contributing

## Important notes

Please don't edit files in the `dist` subdirectory as they are generated via grunt. You'll find source code in the `src` subdirectory!
issuse `bower install` to install dependencies first.

请不要编辑 `dist` 目录下的文件, 这些文件是由 grunt 生成的. 你可以在 `src` 目录下找到源文件.
`src` 下有以 *.coffe, 和 *.js 两种文件, 其中的 *.js 文件是由 `Coffeescript` 生成的. 所以请使用 Coffescript 编写功能, 然后生成 js 文件.

执行 `bower install` 安装依赖.

### Code style

**Two** space indent
naming rules: use underscores to separate name.

缩进为**两个**空格.
命名规则: 使用下划线分隔单词.

### PhantomJS
While grunt can run the included unit tests via [PhantomJS](http://phantomjs.org/), this shouldn't be considered a substitute for the real thing. Please be sure to test the `_SpecRunner.html` unit test file(s) in _actual_ browsers.

See the [Why does grunt complain that PhantomJS isn't installed?](https://github.com/gruntjs/grunt/blob/master/docs/faq.md#why-does-grunt-complain-that-phantomjs-isnt-installed) guide in the [Grunt FAQ](https://github.com/gruntjs/grunt/blob/master/docs/faq.md) for help with installing or troubleshooting PhantomJS.

## Modifying the code
First, ensure that you have the latest [Node.js](http://nodejs.org/) and [npm](http://npmjs.org/) installed.

Test that grunt is installed globally by running `grunt --version` at the command-line.  If grunt isn't installed globally, run `npm install -g grunt` to install the latest version. _You may need to run `sudo npm install -g grunt`._

1. Fork and clone the repo.
1. Run `npm install` to install all dependencies (including grunt).
1. Run `grunt` to grunt this project.

Assuming that you don't see any red, you're ready to go. Just be sure to run `grunt` after making any changes, to ensure that nothing is broken.

## Submitting pull requests

1. Create a new branch, please don't work in your `master` branch directly.
1. Add failing tests for the change you want to make. Run `grunt` to see the tests fail.
1. Fix stuff.
1. Run `grunt` to see if the tests pass. Repeat steps 2-4 until done.
1. Open `_SpecRunner.html` unit test file(s) in actual browser to ensure tests pass everywhere.
1. Update the documentation to reflect any changes.
1. Push to your fork and submit a pull request.
