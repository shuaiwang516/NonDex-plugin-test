import sys
def parse_single_flaky_csv(flaky_csv_file):
    flaky_tests = []
    with open(flaky_csv_file, 'r') as f:
        # ignore the first line
        f.readline()
        for line in f:
            line = line.strip()
            if line == '':
                continue
            flaky_tests.append(line)
    return flaky_tests

def parse_single_result_csv(result_csv_file):
    success_build = {}
    failed_build = {}
    failed_add_plugin = {}
    no_test = {}
    run_time_erorr = {}
    no_flaky_project = {}
    flkay_project = {}
    with open(result_csv_file, 'r') as f:
        # ignore the first line
        f.readline()
        for line in f:
            line = line.strip()
            if line == '':
                continue
            # There are 10 fields in result.csv
            # project name,compile,gradle version,flaky tests,total tests,successful tests,failed tests,skipped tests,time (mins),log size
            fields = line.split(",")
            print(line)
            #print(fields)
            print(result_csv_file)
            compile = fields[1]
            if compile.upper() != "T":
                failed_build[fields[0]] = fields[1:]
            else:
                success_build[fields[0]] = fields[1:]
                flkay_status = fields[3]
                if flkay_status == "run time error":
                    run_time_erorr[fields[0]] = fields[1:]
                elif flkay_status == "fail to add plugin":
                    failed_add_plugin[fields[0]] = fields[1:]
                elif flkay_status == "no test" or fields[4] == "0":
                    no_test[fields[0]] = fields[1:]
                # check whether flkay_status is a number
                elif flkay_status.isdigit():
                    if int(flkay_status) == 0:
                        no_flaky_project[fields[0]] = fields[1:]
                    else:
                        flkay_project[fields[0]] = fields[1:]

    return success_build, failed_build, failed_add_plugin, no_test, run_time_erorr, no_flaky_project, flkay_project

# print(parse_single_result_csv(sys.argv[1])[0])
# print("=====================================")
# print(parse_single_result_csv(sys.argv[1])[1])
# print("=====================================")
# print(parse_single_result_csv(sys.argv[1])[2])
# print("=====================================")
# print(parse_single_result_csv(sys.argv[1])[3])
# print("=====================================")
# print(parse_single_result_csv(sys.argv[1])[4])
# print("=====================================")
# print(parse_single_result_csv(sys.argv[1])[5])
# print("=====================================")
# print(parse_single_result_csv(sys.argv[1])[6])
