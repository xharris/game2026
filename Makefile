run:
	love . 2>&1 | tee logs.txt

test:
	love . 2>&1 | tee test_results.txt