.PHONY: test
test:
	@for f in tests/test_*.lua; do mise exec -- luajit $$f || exit 1; done
