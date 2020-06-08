pipeline {
    agent any
    triggers {
        pollSCM '* * * * *'
    }
    stages {
           stage('buildImage: Jenkins'){     
             steps {
             	openshiftBuild(bldCfg: 'jenkinshrfinora', showBuildLogs: 'true', waitTime: '1800', waitUnit: 'sec')
             }
           }
           stage('deployApplication: Jenkins'){
             steps {
               openshiftDeploy(depCfg: 'jenkinshrfinora',waitTime: '1800', waitUnit: 'sec')
             }
           }
    }
}
