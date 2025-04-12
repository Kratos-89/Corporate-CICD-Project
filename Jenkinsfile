pipeline {
  agent any

  parameters {
    string(name: 'DOCKER_TAG', defaultValue: 'latest', description: 'This is to keep track of the latest docker image tag.')
  }

  tools {
    maven 'maven3'
    jdk 'jdk17'
  }

  environment {
    REPO_URL = 'https://github.com/Kratos-89/Corporate-CICD-Project.git'
    SCANNER_HOME = tool 'sonar-scanner' //Refer the spelling for the scanner in the tools section of jenkins.
    DOCKER_IMAGE = 'docravin/blogapp'
  }

  stages {
    stage('Clean the workspace') {
      //This will clean the workspace to avoid any issues.
      steps {
        cleanWs()
      }
    }

    stage('Git Checkout') {
      steps {
        git branch: 'main', credentialsId: 'git-cred', url: "${REPO_URL}"
      }
    }

    stage('compile') {
      steps {
        sh 'mvn compile'
      }
    }

    stage('Test') {
      steps {
        //Test the code with the test cases in test.txt
        sh 'mvn test'
      }
    }

    stage('Trivy FS Scan') {
      //Scan for any issues in the dependencies(pom.xml)
      steps {
        sh 'trivy fs --format table -o fs.html .' //Make sure you give '.' at the end which specifies the current directory.
      }
    }

    stage('Sonar Analysis') {
      steps {
        //Enter the server name, refer the system section for the sonarqube's server name
        withSonarQubeEnv('SonarQube-Server') {
          sh ''' $SCANNER_HOME/bin/sonar-scanner -Dsonar.projectName=blogapp -Dsonar.projectKey=blog -Dsonar.java.binaries=target'''
        }
      }
    }

    //Build the artifact.
    stage('Build') {
      steps {
          sh 'mvn package'
      }
    }

    stage('Publish Artifact') {
        steps {
          //Publishes the artifact to the nexus repository.
          withMaven(globalMavenSettingsConfig:'maven-settings-config', jdk:'jdk17', maven:'maven3', mavenSettingsConfig:'', traceability:true) {
            sh 'mvn deploy'
          }
        }
    }

    stage('Docker Build') {
        steps {
          script {
            withDockerRegistry(credentialsId:'doc-cred') {
              sh "docker build -t ${DOCKER_IMAGE}:${params.DOCKER_TAG} ."
            //archiveArtifacts artifacts: 'img.html', allowEmptyArchive: true
            }
          }
        }
    }

    stage('Trivy Image Scan') {
      steps {
        withEnv(["DOCKER_IMAGE=${DOCKER_IMAGE}", "DOCKER_TAG=${params.DOCKER_TAG}"]) {
          sh '''
      #!/bin/bash
      trivy image --format table -o img.html ${DOCKER_IMAGE}:${DOCKER_TAG}
      '''
        }
      }
    }

    stage('Docker Push') {
      steps {
        script {
          withDockerRegistry(credentialsId: 'doc-cred') {
            sh "docker push ${DOCKER_IMAGE}:${params.DOCKER_TAG}"
          }
        }
      }
    }

    stage('Update the YAML files in the Corporate CICD Repo') {
      //The purpose of this stage is to update the docker image's latest tag in the deployment file of the app.
      steps {
        script {
          withCredentials([gitUsernamePassword(credentialsId: 'git-cred', gitToolName : 'Default')]) {
            sh '''
            git clone ${REPO_URL}
            cd Corporate-CICD-Project

            ls -l

            repo_dir=$(pwd)
            #Replace the tag.
            sed -i "s|image: ${DOCKER_IMAGE}:.*|image: ${DOCKER_IMAGE}:${DOCKER_TAG}|" ${repo_dir}/kube-files/deployments.yaml
            echo "Updated the deployment file"
            cat kube-files/deployments.yaml
            git config user.email "jenkins@cicd.com"
            git config user.name "jenkins"
            git add kube-files/deployments.yaml
            git commit -m "Updated Docker image tag to ${DOCKER_TAG}"
            git push origin main
            '''
          }
        }
      }
    }

    stage('k8-Deploy') {
      steps {
        withKubeConfig(caCertificate:'', clusterName:'blogapp_cluster', contextName:'', credentialsId:'k8-cred', namespace:'webapps', restrictKubeConfigAccess:false, serverUrl:'https://48AAC4877E46F497077BC865B7E4C2F9.gr7.us-east-1.eks.amazonaws.com')//api server endpoint url
        {
          sh 'kubectl apply -f kube-files/deployments.yaml'
          sh 'kubectl rollout status deployment/blog-app-deployment'
        //The above command is a dynamic command which waits and outputs the success message once the desired state of the deployment is achieved, else it outputs a error message once time-outs.
        }
      }
    }

    stage('Verify Deployment') {
      steps {
        withKubeConfig(caCertificate:'', clusterName:'clusterName', contextName:'', credentialsId:'k8-cred', namespace:'webapps', restrictKubeConfigAccess:false, serverUrl:'https://48AAC4877E46F497077BC865B7E4C2F9.gr7.us-east-1.eks.amazonaws.com') {
          sh 'kubectl get pods'
          sh 'kubectl get svc'
        }
      }
    }
  }
  post {
      always {
        script {
          def jobName = env.JOB_NAME
          def buildNumber = env.BUILD_NUMBER
          def pipelineStatus = currentBuild.result ?: 'UNKNOWN'
          def bannerColor = pipelineStatus.toUpperCase() == 'SUCCESS' ? 'green' : 'red'
          def body = """
            <html>
            <body>
            <div style="border: 4px solid ${bannerColor}; padding: 10px;">
            <h2>${jobName} - Build ${buildNumber}</h2>
            <div style="background-color: ${bannerColor}; padding: 10px;">
            <h3 style="color: white;">Pipeline Status: ${pipelineStatus.toUpperCase()}</h3>
            </div>
            <p>Check the <a href="${BUILD_URL}">console output</a>.</p>
            </div>
            </body>
            </html>
            """
          emailext(
            subject: "${jobName} - Build ${buildNumber} - ${pipelineStatus.toUpperCase()}",
            body: body,
            to: 'ravindar.inbox@gmail.com',
            from: 'jenkins@example.com',
            replyTo: 'jenkins@example.com',
            mimeType: 'text/html',
            attachmentsPattern: 'img.html')
      }
    }
  }
}
