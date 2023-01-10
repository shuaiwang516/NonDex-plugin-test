# this script automate running test on project

# 1. if the **dir exist**, cd to it; else clone the project and cd to it
# 2. try to **compile** it, if fail, write a result entry `$repo,F,` and skip to the next
# 3. if success, modify the 'build.gradle' to include the plugin
# 4. try to **compile** it, if fail, write a result entry `$repo,T,F`, else `$repo,T,T`.

# by "compile", I mean to run `./gradlew tasks`
path=$(pwd)
echo $path
result_file=${path}/result.csv

function download_compile() {
    cd $path
    user=$(dirname $1)
    repo=$(basename $1)
    dir=github.com/${user}/${repo}
    url=http://github.com/${user}/${repo}.git
    git clone $url ${dir}
    cd $dir

    # ---------------build the project-----------------------#
    ./gradlew tasks > temp.log
    grep "BUILD SUCCESSFUL" temp.log

    
    if [ $? == 0 ]; then # if build success
        echo try to add the plugin
        echo "apply plugin: 'edu.illinois.nondex'" >> build.gradle
        # grep "classpath 'edu.illinois.nondex:edu.illinois.nondex.gradle.plugin:2.1.1'" build.gradle
        echo "buildscript {
  repositories {
    mavenLocal()
    mavenCentral()
  }
  dependencies {
    classpath 'edu.illinois.nondex:edu.illinois.nondex.gradle.plugin:2.1.1'
  }
}
$(cat build.gradle)" > build.gradle
        # try to run with the plugin
        ./gradlew tasks > temp.log
        grep -i "nondex" temp.log
        if [ $? == 0 ]; then # if success
            echo $1,T,T | tr '\n' ',' >> ${result_file} # so it doesn't change line
            echo success to add the plugin, try to run nondexTest
            ./gradlew nondexTest > temp.log
            grep "test_results.html" temp.log >> ${result_file}
            if [ $? != 0 ]; then
              echo >> ${result_file} # no tests or run time error
              echo no tests or nondexTest runtime error
            fi
        else
            echo $1,T,F, >> ${result_file}
            echo fail to add plugin
        fi
    else # fail
        echo $1,F,, >> ${result_file}
        echo project has error
        cat temp.log  # print build error message
    fi
}

# touch result.csv
# for f in $(cat $1); do
#     echo ========== trying to dowload $f
#     download_compile $f
# done

download_compile $1
