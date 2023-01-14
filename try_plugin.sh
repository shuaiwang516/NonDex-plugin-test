# this script automate running test on project

# should use java veresion higher than 8, maybe 11. Because many projects are of higher version.

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

	chmod +x gradlew
    # ----------------------------------------------------check gradle version--------------------------------------------------------#
	ver=$(grep distributionUrl gradle/wrapper/gradle-wrapper.properties | sed 's/.*gradle-//' | cut -f1 -d-)
	echo gradle version: $ver
	bigger_ver=$(echo -e "$ver\n4.7" | sort -rV | head -n 1)
	version_change=F
	if [[ $ver != ${bigger_ver} ]]; then # the version is smaller than 4.7
		version_change=T
		sed -i 's/distributionUrl.*//' gradle/wrapper/gradle-wrapper.properties
		echo "distributionUrl=https\://services.gradle.org/distributions/gradle-4.7-bin.zip" >> gradle/wrapper/gradle-wrapper.properties
		if [ $? == 0 ]; then # there is a wrapper block
			sed -i 's/.*gradleVersion.*/    gradleVersion = "4.7"/' build.gradle 
		fi
	fi

    # ----------------------------------------------------build the project--------------------------------------------------------#
    echo try to build the project
	./gradlew tasks 1> build.log 2> build-err.log
    grep "BUILD SUCCESSFUL" build.log

    
    if [ $? == 0 ]; then # if build success
		build=T

    # ----------------------------------------------------adding the plugin-----------------------------------------------------------#
        echo try to add the plugin
		grep "classpath 'edu.illinois.nondex:edu.illinois.nondex.gradle.plugin:2.1.1'" build.gradle
		if [ $? != 0 ]; then
        	echo -e "\napply plugin: 'edu.illinois.nondex'" >> build.gradle
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
        fi
        # -----------------------------------------------------run nondexTest--------------------------------------------------------------#
        echo try to run nondexTest
        ./gradlew nondexTest --nondexRuns=10 1> nondex.log 2> nondex-err.log
		grep "NonDex SUMMARY:" nondex.log
		if [ $? == 0 ]; then # if nondexTest is actually executed
			flaky_tests=$(sed -n -e '/Across all seeds:/,/Test results can be found at: / p' nondex.log | sed -e '1d;$d' | cut -f2 -d' ' | tr '\n' ';' | sed 's/.$//') # no new line char at the end
      		if [[ $flaky_tests = '' ]]; then flaky_tests="no flaky tests"; fi
    	else
			echo "error or no test in the project"
			grep "BUILD SUCCESSFUL" nondex.log
			if [ $? == 0 ]; then
				flaky_tests="no test"
			else
				flaky_tests="error"
			fi
			cp nondex-err.log ${path}/error_log/nondex-${user}-${repo}.log
		fi
    else 
    # ----------------------------------------build fail------------------------------------------------ #
        build=F
        flaky_tests="N/A"
        echo project has error
        cp build-err.log ${path}/error_log/build-${user}-${repo}.log
    fi
	echo -e "$1,${build},${ver},${flaky_tests}" >> ${path}/result.csv
}

touch result.csv
echo "project name,compile,gradle version,flaky tests" > result.csv
mkdir error_log
for f in $(cat $1); do
    echo ========== trying to dowload $f
    download_compile $f
done
