*! 
*!

set more off
*set trace off
clear all

vers 11.0
global clusters 1 2 3 4 5 6 7 8

/* Creating a set of random datasets */
set seed 10
global N 100000
global k 10
global F 16

set obs $N

gen x0 = _n
forval i=1/$k {
	gen double x`i' = runiform()*`i'
}

summ x2-x$k

/* Creating the dir */
cap cd test_append
if (_rc) mkdir test_append, public
else {
	cd ..
	local dirs : dir "test_append" files "*"
	foreach f of local dirs {
		rm test_append/`f'
	}
}

/* Splitting the dataset */
local size = floor($N/$F)
forval i=1/$F {
	preserve
	if (`i' == $F) keep if x0 >= $F*(`i'-1)
	else keep if inrange(x0,$F*(`i'-1)+1,$F*`i')
	save test_append/part`i', replace
	restore
}

/* Setting the tests */
local filelist : dir "test_append" files "*.dta"
local filelist_rpath : subinstr local filelist "part" "test_append/part", all
local test1 parallel append `filelist_rpath', do(collapse _all) keeplast
local test2 parallel append, do(collapse _all) exp("test_append/part%g,1/$F") keeplast
local test1 parallel append, do(collapse _all) exp("test_append/part%g.dta,1/$F") keeplast
local test4 parallel append, do(collapse _all) exp("../test files/test_append/part%g.dta,1/$F") keeplast

foreach c of global clusters {

	parallel setclusters `c', force hostnames(`: env PLL_TEST_NODES')
	local i 0
	while (`"`test`++i''"'!= "") {
		//quietly {
			`test`i''
			collapse _all
		//}
		di `"{result:CMD: `test`i''}"'
		list
	}
	
}

forval i=1/$F {
	rm test_append/part`i'.dta
}
rmdir test_append

