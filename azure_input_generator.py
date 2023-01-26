import os, sys

# Input Format: NonDex-plugin-test-repo-url, sha, project_name (separated by %)
nondex_git_url = "https://github.com/MarcyGO/NonDex-plugin-test.git"

def generate_input_str(git_url, commit, project_list):
    project_str = "%".join(project_list)
    return f"{git_url},{commit},{project_str}"


def get_project_list_from_file(file_path):
    with open(file_path, "r") as f:
        project_list = f.readlines()
    project_list = [proj.strip() for proj in project_list]
    return project_list


# split the test list into chunks
def split_proj_list(proj_list, chunk_size):
    proj_list_chunks = []
    for i in range(0, len(proj_list), chunk_size):
        proj_list_chunks.append(proj_list[i:i + chunk_size])
    return proj_list_chunks


# generate input for each chunk
def generate_input_for_each_chunk(git_url, commit, project_name, proj_list, chunk_size):
    proj_list_chunks = split_proj_list(proj_list, chunk_size)
    input_str_list = []
    for proj_list_chunk in proj_list_chunks:
        input_str = generate_input_str(git_url, commit, proj_list_chunk)
        input_str_list.append(input_str)
    return input_str_list


# Create input files for each chunk
def create_input_files(project_name, input_str_list, output_dir):
    # create output directory if not exist, delete all files in the directory if exist
    output_dir = os.path.join(output_dir, project_name)
    if not os.path.exists(output_dir):
        os.makedirs(output_dir)
    else:
        for file in os.listdir(output_dir):
            os.remove(os.path.join(output_dir, file))
    for i, input_str in enumerate(input_str_list):
        with open(os.path.join(output_dir, f"{project_name}_input_{i}.csv"), "w") as f:
            f.write(input_str)


if __name__ == '__main__':
    if (len(sys.argv) != 5):
        raise ValueError("Usage: python3 generate_azure_input.py <commit> <project_list_file> <proj_num_per_vm> <output_dir>")
    commit, project_list_file, proj_num_per_vm, output_dir = sys.argv[1:]
    project_list = get_project_list_from_file(project_list_file)
    create_input_files("NONDEX", generate_input_for_each_chunk(nondex_git_url, commit, "NONDEX", project_list, int(proj_num_per_vm)), output_dir)