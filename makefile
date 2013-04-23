all: update-js

update-js:
	@git show master:dist/js/jquery.atwho.min.js > assets/js/jquery.atwho.min.js
	@git show master:dist/js/jquery.atwho.js > assets/js/jquery.atwho.js
