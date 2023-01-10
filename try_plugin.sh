# this script automate running test on project

# should use java veresion higher than 8, maybe 11. Because many projects are of higher version.

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

    # ----------------------------------------------------build the project--------------------------------------------------------#
    chmod +x gradlew
    ./gradlew tasks > build.log
    grep "BUILD SUCCESSFUL" build.log

    
    if [ $? == 0 ]; then # if build success
		build=T
    # ----------------------------------------------------check gradle version--------------------------------------------------------#
		ver=$(./gradlew -version | grep "Gradle " | cut -f2 -d' ')
		bigger_ver=$(echo -e "$ver\n4.7" | sort -rV | head -n 1)
		version_change=F
		if [[ $ver != ${bigger_ver} ]]; then # the version is smaller than 4.7
			version_change=T
			grep gradleVersion build.gradle
			if [ $? == 0 ]; then # there is a wrapper block
				sed 's/.*gradleVersion.*/    gradleVersion = "4.7"/' build.gradle
			else
				./gradlew wrapper --gradle-version=4.7 --distribution-type=bin
				# will this has error?
			fi
		fi
    # ----------------------------------------------------adding the plugin-----------------------------------------------------------#
        echo try to add the plugin
        echo "apply plugin: 'edu.illinois.nondex'" >> build.gradle
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
        
        # -----------------------------------------------------run nondexTest--------------------------------------------------------------#
        echo try to run nondexTest
        ./gradlew nondexTest --nondexRuns=10 > nondex.log
		grep "NonDex SUMMARY:" nondex.log
		if [ $? == 0 ]; then # if nondexTest is actually executed
			flaky_tests=$(sed -n -e '/Across all seeds:/,/Test results can be found at: / p' nondex.log | sed -e '1d;$d' | cut -f2 -d' ' | tr '\n' ';' | sed 's/.$//') # no new line char at the end
      		if [[ $flaky_tests = '' ]]; then flaky_tests="no flaky tests"; fi
    	else
			echo error or no test in the project
			grep "BUILD SUCCESSFUL" nondex.log
			if [ $? == 0 ]; then
				flaky_tests="no test"
			else
				flaky_tests="error"
			fi
			cp nondex.log ${path}/error_log/nondex-${user}-${repo}.log
		fi
    else 
    # ----------------------------------------build fail------------------------------------------------ #
        build=F
        flaky_tests="N/A"
		version_change="N/A"
        echo project has error
        cp build.log ${path}/error_log/build-${user}-${repo}.log
    fi
	echo -e "$1,${build},${version_change},${flaky_tests}" >> ${path}/result.csv
}

touch result.csv
echo "project name,compile,change gradle version,flaky tests" > result.csv
mkdir error_log
for f in $(cat $1); do
    echo ========== trying to dowload $f
    download_compile $f
done
