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
	bigger_ver=$(echo -e "$ver\n5.0" | sort -rV | head -n 1)
	version_change=F
	if [[ $ver != ${bigger_ver} ]]; then # the version is smaller than 5.0
		version_change=T
		sed -i 's/distributionUrl.*//' gradle/wrapper/gradle-wrapper.properties
		echo "distributionUrl=https\://services.gradle.org/distributions/gradle-5.0-bin.zip" >> gradle/wrapper/gradle-wrapper.properties
		if [ $? == 0 ]; then # there is a wrapper block
			sed -i 's/.*gradleVersion.*/    gradleVersion = "5.0"/' build.gradle 
		fi
	fi

    # ----------------------------------------------------build the project--------------------------------------------------------#
    echo try to build the project
	./gradlew tasks 1> build.log 2> build-err.log
    grep "BUILD SUCCESSFUL" build.log

    
    if [ $? == 0 ]; then # if build success
		build=T
		projects=$(./gradlew projects | grep Project | cut -f3 -d" " | tr -d "':")
    # ----------------------------------------------------adding the plugin-----------------------------------------------------------#
        echo try to add the plugin
		grep "classpath 'edu.illinois.nondex:edu.illinois.nondex.gradle.plugin:2.1.1'" build.gradle
		if [ $? != 0 ]; then
			./gradlew projects | grep "No sub-projects"
			sub=$?	# sub=0 if no subprojects; sub=1 if there are subprojects
			if [ $sub == 0 ]; then # no subprojects
				echo -e "\napply plugin: 'edu.illinois.nondex'" >> build.gradle
			else
				echo -e "\nsubprojects {\n    apply plugin: 'edu.illinois.nondex'\n}" >> build.gradle
			fi
        	
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

		# change test closures to tasks.withType(Test)
		sed -i 's/test /tasks.withType(Test) /' build.gradle
		if [[ $sub != 0 ]]; then # have subprojects
			for p in ${projects}; do 
				sed -i 's/^\( \|\t\)*test /tasks.withType(Test) /' $p/build.gradle
			done
		fi
        # -----------------------------------------------------run nondexTest--------------------------------------------------------------#
        echo try to run nondexTest
		./gradlew clean	# so always run nondexTest even if the last run is a success

		if [[ $sub == 0 ]]; then	# no subprojects
			./gradlew nondexTest --nondexRuns=10 1> nondex.log 2> nondex-err.log
			if ( grep "NonDex SUMMARY:" nondex.log ); then # if nondexTest is actually executed
				flaky_tests=$(sed -n -e '/Across all seeds:/,/Test results can be found at: / p' nondex.log | sed -e '1d;$d' | cut -f1 -d' ' --complement | tr '\n' ';' | sed 's/.$//') # no new line char at the end
				if [[ $flaky_tests = '' ]]; then flaky_tests="no flaky tests"; fi
			else
				echo "error or no test in the project"
				if ( grep "BUILD SUCCESSFUL" nondex.log ); then flaky_tests="no test"
				else flaky_tests="error"; cp nondex-err.log ${path}/error_log/nondex-${user}-${repo}.log; fi
			fi
			echo -e "$1,${build},${ver},${flaky_tests}" >> ${path}/result.csv
		else	# run each subprojects separately, cuz nondex generate summary report for each subprojects
			for p in ${projects}; do 
				./gradlew :$p:nondexTest  --nondexRuns=10 1> nondex:$p.log 2> nondex-err:$p.log
				if ( grep "NonDex SUMMARY:" nondex:$p.log ); then # if nondexTest is actually executed
					flaky_tests=$(sed -n -e '/Across all seeds:/,/Test results can be found at: / p' nondex:$p.log | sed -e '1d;$d' | cut -f1 -d' ' --complement | tr '\n' ';' | sed 's/.$//') # no new line char at the end
					if [[ $flaky_tests = '' ]]; then flaky_tests="no flaky tests"; fi
				else
					echo "error or no test in the project"
					if ( grep "BUILD SUCCESSFUL" nondex:$p.log ); then flaky_tests="no test"
					else flaky_tests="error"; cp nondex-err:$p.log ${path}/error_log/nondex-${user}-${repo}:$p.log; fi
				fi
				echo -e "$1:$p,${build},${ver},${flaky_tests}" >> ${path}/result.csv
			done
		fi
    else 
    # ----------------------------------------build fail------------------------------------------------ #
        build=F
        flaky_tests="N/A"
        echo project has error
        cp build-err.log ${path}/error_log/build-${user}-${repo}.log
		echo -e "$1,${build},${ver},${flaky_tests}" >> ${path}/result.csv
    fi
	# echo -e "$1,${build},${ver},${flaky_tests}" >> ${path}/result.csv
}

touch result.csv
echo "project name,compile,gradle version,flaky tests" > result.csv
mkdir error_log
for f in $(cat $1); do
    echo ========== trying to dowload $f
    download_compile $f
done
