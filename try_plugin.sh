# this script automate running test on project

# should use java veresion higher than 8, maybe 11. Because many projects are of higher version.

CUR_DIR=$(pwd)
mkdir -p ${CUR_DIR}/output
path=${CUR_DIR}/output
echo $path

function download_compile() {
    start_time=$(date +%s)
    cd $CUR_DIR
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
    echo ========= try to build the project
    ./gradlew tasks 1> build.log 2> build-err.log
    # append to a output file
    echo ========= try to build the project >> azure_build.log && cat build.log >> azure_build.log
    echo ========= try to build the project >> azure_build_err.log && cat build-err.log >> azure_build_err.log
    cp azure_build.log  ${path}/azure_build.log
    cp azure_build_err.log ${path}/azure_build_err.log
    
    
    grep "BUILD SUCCESSFUL" build.log
    
    if [ $? == 0 ]; then # if build success
		build="error with test"
		./gradlew projects | grep "No sub-projects"
		sub=$?	# sub=0 if no subprojects; sub=1 if there are subprojects
		projects=$(./gradlew projects | grep Project | sed 's/^.*Project//' | tr -d " '")
		buildFile=$(./gradlew properties | grep buildFile | awk '{print $2}')
		# ----------count total tests-------------------- #
		echo '
allprojects {
  tasks.withType(Test) {
    testLogging {
      afterSuite { desc, result ->
        if (!desc.parent) { 
          println "+++Results: ${result.resultType} ${result.testCount},${result.successfulTestCount},${result.failedTestCount},${result.skippedTestCount}"
        }
      }
    }
  }
}' >> ${buildFile}
		echo ========== run tests without NonDex
		./gradlew test | grep "+++Results"
		if [ $? == 0 ]; then build="T"; else echo "========== error with test"; fi # able to run test

    # ----------------------------------------------------adding the plugin-----------------------------------------------------------#
        echo ========== try to add the plugin
		grep "classpath 'edu.illinois.nondex:edu.illinois.nondex.gradle.plugin:2.1.1'" ${buildFile}
		if [ $? != 0 ]; then
			if [ $sub == 0 ]; then # no subprojects
				echo -e "\napply plugin: 'edu.illinois.nondex'" >> ${buildFile}
			else
				echo -e "\nsubprojects {\n    apply plugin: 'edu.illinois.nondex'\n}" >> ${buildFile}
			fi
        	echo "buildscript {
  repositories {
    maven {
      url = uri('https://plugins.gradle.org/m2/')
    }
  }
  dependencies {
    classpath('edu.illinois:plugin:2.1.1')
  }
}
$(cat ${buildFile})" > ${buildFile}
        fi

		# change test closures to tasks.withType(Test)
		sed -i 's/^\( \|\t\)*test /tasks.withType(Test) /' ${buildFile}
		if [[ $sub != 0 ]]; then # have subprojects
			for p in ${projects}; do
				subBuildFile=$(./gradlew $p:properties | grep buildFile | awk '{print $2}')
				sed -i 's/^\( \|\t\)*test /tasks.withType(Test) /' ${subBuildFile}
			done
		fi
        # -----------------------------------------------------run nondexTest--------------------------------------------------------------#
        echo ========== try to run nondexTest
		./gradlew clean	# so always run nondexTest even if the last run is a success
		if [[ $sub == 0 ]]; then	# no subprojects
			total_tests=$(./gradlew test | grep "+++Result" | cut -f3 -d' ')
			if [[ ${total_tests} == '' ]]; then total_tests=",,,"; echo "========== error with tests in $1";fi
			echo "========== run NonDex on $1"
			./gradlew nondexTest --nondexRuns=50 1> nondex.log 2> nondex-err.log

			echo "========== run NonDex on $1" >> azure_nondex.log && cat nondex.log >> azure_nondex.log
			echo "========== run NonDex on $1" >> azure_nondex_err.log && cat nondex-err.log >> azure_nondex_err.log
			cp azure_nondex.log  ${path}/azure_nondex.log
			cp azure_nondex_err.log ${path}/azure_nondex_err.log

			size_std=$(du nondex.log | cut -f1)
			size_err=$(du nondex-err.log | cut -f1)
			if ( grep "NonDex SUMMARY:" nondex.log ); then # if nondexTest is actually executed
				flaky_tests=$(sed -n -e '/Across all seeds:/,/Test results can be found at: / p' nondex.log | sed -e '1d;$d' | wc -l)
				if [[ $flaky_tests != '0' ]]; then 
					sha=$(git rev-parse HEAD)
					sed -n -e '/Across all seeds:/,/Test results can be found at: / p' nondex.log | sed -e '1d;$d' | cut -f1 -d' ' --complement | while read line
					do echo "https://github.com/$1,${sha},.,${line}" >> ${path}/flaky.csv
					done	
				fi
			else
				echo "========== error or no test in the project $1"
				if ( grep "BUILD SUCCESSFUL" nondex.log ); then flaky_tests="no test"
				elif ( ./gradlew tasks | grep nondexTest ); then flaky_tests="run time error"; cp nondex-err.log ${path}/error_log/nondex-${user}-${repo}.log
				else flaky_tests="fail to add plugin"; fi
			fi
			echo -e "$1,${build},${ver},${flaky_tests},${total_tests},$(( ($(date +%s)-${start_time})/60 )),$(( ${size_std}+${size_err} ))" | tee -a ${path}/result.csv
		else	# run each subprojects separately, cuz nondex generate summary report for each subprojects
			for p in ${projects}; do 
				total_tests=$(./gradlew $p:test | grep "+++Result" | cut -f3 -d' ' | head -n 1)
				if [[ ${total_tests} == '' ]]; then total_tests=",,,"; echo "========== error with tests in $1$p";fi
				echo "========== run NonDex on $1$p"
				./gradlew $p:nondexTest  --nondexRuns=50 1> nondex$p.log 2> nondex-err$p.log
				echo "========== run NonDex on $1$p" &&	cat nondex$p.log > azure_nondex$p.log
				echo "========== run NonDex on $1$p" &&	cat nondex-err$p.log > azure_nondex_err$p.log
				cp azure_nondex$p.log   ${path}/azure_nondex$p.log
				cp azure_nondex_err$p.log ${path}/azure_nondex_err$p.log
				size_std=$(du nondex$p.log | cut -f1)
				size_err=$(du nondex-err$p.log | cut -f1)
				if ( grep "NonDex SUMMARY:" nondex$p.log ); then # if nondexTest is actually executed
					flaky_tests=$(sed -n -e '/Across all seeds:/,/Test results can be found at: / p' nondex$p.log | sed -e '1d;$d' | wc -l)
					if [[ $flaky_tests != '0' ]]; then
						sha=$(git rev-parse HEAD)
						sed -n -e '/Across all seeds:/,/Test results can be found at: / p' nondex$p.log | sed -e '1d;$d' | cut -f1 -d' ' --complement | while read line
						do echo "https://github.com/$1,${sha},$p,${line}" >> ${path}/flaky.csv
						done
					fi
				else
					echo "========== error or no test in the project $1$p"
					if ( grep "BUILD SUCCESSFUL" nondex$p.log ); then flaky_tests="no test"
					elif ( ./gradlew tasks | grep nondexTest ); then flaky_tests="run time error"; cp nondex-err$p.log ${path}/error_log/nondex-${user}-${repo}$p.log
					else flaky_tests="fail to add plugin"; fi
				fi
				echo -e "$1$p,${build},${ver},${flaky_tests},${total_tests},$(( ($(date +%s)-${start_time})/60 )),$(( ${size_std}+${size_err} ))" | tee -a ${path}/result.csv
			done
		fi
    else 
    # ----------------------------------------build fail------------------------------------------------ #
        build="F"
        flaky_tests="N/A"
		total_tests=",,,"
        echo "project $1 has error"
        cp build-err.log ${path}/error_log/build-${user}-${repo}.log
		size_std=$(du build.log | cut -f1)
		size_err=$(du build-err$p.log | cut -f1)
		echo -e "$1,${build},${ver},${flaky_tests},${total_tests},$(( ($(date +%s)-${start_time})/60 )),$(( ${size_std}+${size_err} ))" >> ${path}/result.csv
    fi
}

echo script SHA: $(git rev-parse HEAD)
script_start_time=$(date +%s)
echo "project name,compile,gradle version,flaky tests,total tests,successful tests,failed tests,skipped tests,time (mins),log size" > output/result.csv
echo "Project URL,SHA Detected,Subproject Name,Fully-Qualified Test Name (packageName.ClassName.methodName)" > output/flaky.csv
mkdir -p output/error_log
proj=$1
# sepearte the project with "%" and stores into a list called projects
IFS='%' read -a projects <<< "$proj"
for proj in "${projects[@]}"
do
	echo ========== trying to dowload $proj
    download_compile $proj
done
script_end_time=$(date +%s)
echo total time in minutes: $(( ($(date +%s)-${start_time})/60 ))
