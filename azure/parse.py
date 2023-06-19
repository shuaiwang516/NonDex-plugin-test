import os,sys
import parse_single

'''
1) parse flaky.csv to get all flaky tests
2) parse all files in error_log dir to get all failed build project name
3) parse result.csv to get all metrics
'''

FLAKY_CSV_TITLE = "Project URL,SHA Detected,Subproject Name,Fully-Qualified Test Name (packageName.ClassName.methodName)"
RESULT_CSV_TITLE = "project name,compile,gradle version,flaky tests,total tests,successful tests,failed tests,skipped tests,time (mins),log size"
projects = set()
flaky_csv = []
result_csv = []
# error_build_proj = []

success_build = {}
failed_build = {}
failed_add_plugin = {}
no_test = {}
run_time_erorr = {}
no_flaky_project = {}
flkay_project = {}


# ======= Helper Function ========
def write_dict_to_file(file_name, dict):
    with open(file_name, "w") as f:
        f.write(RESULT_CSV_TITLE + "\n")
        for key in dict:
            f.write(key + "," + ",".join(dict[key]) + "\n")

def write_set_to_file(file_name, target_set):
    with open(file_name, "w") as f:
        for element in target_set:
            f.write(element + "\n")
            
def parse_data_from_dir(dir):
    for root, dirs, files in os.walk(dir):
        for file in files:

            # if flaky.csv file
            if file == "flaky.csv":
                flaky_tests = parse_single.parse_single_flaky_csv(os.path.join(root, file))
                # add flaky tests to flaky_csv
                flaky_csv.append(flaky_tests)
            # if result.csv file
            elif file == "result.csv":
                results = parse_single.parse_single_result_csv(os.path.join(root, file))
                # append the return value to success_build, failed_build, failed_add_plugin, no_test, run_time_erorr, no_flaky_project, flkay_project
                success_build.update(results[0])
                failed_build.update(results[1])
                failed_add_plugin.update(results[2])
                no_test.update(results[3])
                run_time_erorr.update(results[4])
                no_flaky_project.update(results[5])
                flkay_project.update(results[6])                
            # if file in error_log dir
            # elif root.split("/")[-1] == "error_log":
            #     # add project name to error_build_proj
            #     # remove suffix, and the front prefix as "build-"
            #     error_build_proj.append(file.split("/")[-1].replace("build-", "").replace(".log", "").replace("-", "/"))

    result_csv = [success_build, failed_build, failed_add_plugin, no_test, run_time_erorr, no_flaky_project, flkay_project]
    return sorted(flaky_csv), result_csv

def output_result_summary():
    print("===============Results of NonDex======================")
    print("Total number of projects: " + str(len(success_build) + len(failed_build)))
    print("Number of failed compiled projects: " + str(len(failed_build)))
    print("Number of successful compiled projects: " + str(len(success_build)))
    print("Number of projects failed adding NonDex plugin: " + str(len(failed_add_plugin)))
    print("Number of projects got run time error: " + str(len(run_time_erorr)))
    print("Number of projects with no test: " + str(len(no_test)))
    print("Number of projects have no flaky test: " + str(len(no_flaky_project)))
    print("Number of projects have flaky test: " + str(len(flkay_project)))
    print("======================================================")


def output_result_to_file(output_dir):
    if os.path.exists(output_dir):
        # remove the dir
        os.system("rm -rf " + output_dir)
    os.makedirs(output_dir)
    # write all failed build projects to file
    write_dict_to_file(os.path.join(output_dir, "failed_build_proj.csv"), failed_build)
    # write all failed run project to file
    # create a new dict called failed_run_proj that adds failed_add_plugin, run_time_erorr together
    failed_run_proj = failed_add_plugin.copy()
    failed_run_proj.update(run_time_erorr)
    write_dict_to_file(os.path.join(output_dir, "failed_run_proj.csv"), failed_run_proj)
    # write all no test project to file
    write_dict_to_file(os.path.join(output_dir, "no_test_proj.csv"), no_test)
    # write all no flaky project to file
    write_dict_to_file(os.path.join(output_dir, "no_flaky_proj.csv"), no_flaky_project)
    # write all flaky project to file
    write_dict_to_file(os.path.join(output_dir, "flaky_proj.csv"), flkay_project)
    # write all projects to file
    get_all_project_name()
    write_set_to_file(os.path.join(output_dir, "project_list.csv"), projects)
    

def get_all_project_name():
    for key in success_build.keys():
        projects.add(key)
    for key in failed_build.keys():
        projects.add(key)
    return projects
    

def parse(data_dir, output_dir):
    parse_data_from_dir(data_dir)
    output_result_summary()
    output_result_to_file(output_dir)


# print(parse_data_from_dir(sys.argv[1])[0])
# print("=====================================")
# print(parse_data_from_dir(sys.argv[1])[1])
# print("=====================================")
# print(parse_data_from_dir(sys.argv[1])[2])

parse(sys.argv[1], sys.argv[2])
