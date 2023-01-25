# NonDex-plugin-test
Scripts and files used to test the plugin

repos.txt file contains non-Android Gradle projects collected using github search API, sorted by stars.

To run the whole project list: ./try_plugin searchForProjects/repos.txt (run with JAVA 11)
Output:
  1. error-log directory
  2. result.csv records build result for each project
  3. flaky.csv records flaky tests
  
