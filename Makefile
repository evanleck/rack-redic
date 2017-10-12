.DEFAULT_GOAL := test
.PHONY: test
.SILENT: test

BE := bundle exec

# Run our test suite.
#
# To test an individual file, pass the "file" argument like so:
#
#   make test file=test/storage_test.rb
#
test:
ifeq ($(origin file), undefined)
	$(BE) ruby -r ./test/helper.rb test/all.rb
else
	$(BE) ruby -r ./test/helper.rb $(file)
endif
