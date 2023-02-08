path_to_flaky="flaky.csv" # output files after merge
path_to_result="result.csv"
flaky_projects=$(($(cut -f1 -d, ${path_to_flaky} | sort | uniq | wc -l)-1))
total_flaky_tests=$(($(wc -l ${path_to_flaky} | cut -f1 -d' ' )-1))
compiled_projects=$(< ${path_to_result} sed 's/$/\n/' | column -s, -t | grep -w "T" | cut -f1 -d' ' | cut -f1 -d: | sort | uniq | wc -l)
no_flaky=$(< result.csv sed 's/$/\n/' | column -s, -t | awk '$4 == "0"' | cut -f1 -d' ' | cut -f1 -d: | sort | uniq | wc -l)
error=$(< result.csv sed 's/$/\n/' | column -s, -t | awk '$4 == "error"' | cut -f1 -d' ' | cut -f1 -d: | sort | uniq | wc -l)
no_test=$(< result.csv sed 's/$/\n/' | grep "no test" | cut -f1 -d' ' | cut -f1 -d: | sort | uniq | wc -l)

echo "total number of built projects: $compiled_projects"
echo "number of projects with at least one flaky test: $flaky_projects"
echo "total number of flaky tests detected: $total_flaky_tests"
echo "number of projects that have error with the plugin: $error"
echo "number of projects with no tests: $no_test"
