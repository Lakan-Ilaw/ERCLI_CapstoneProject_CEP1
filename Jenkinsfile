pipeline {
  agent any
  environment {
    mavenHome = tool name: 'maven' , type: 'maven'
    tag="latest"
    dockerHubUser="lakanilaw"
    containerName="ercli-asi-insurance_cep1"
    httpPort="8081"
    workingDir="/home/elmerlakanilawy/CapstoneProject/ERCLI-CEP1/"
  }
  stages {
    stage('Prepare Environment'){
      steps {
        echo 'Initialize Environment'
        echo "Tag: $tag | Docker Hub User: $dockerHubUser | Container Name: $containerName | Port: $httpPort
      }
    }
    stage('Clone Repository') {
      checkout scm  
    }

    stage('Maven Build'){
      steps {
        sh "${mavenHome} clean package"
      }
    }
    stage('Publish Test Reports'){
      steps {
        publishHTML([allowMissing: false, alwaysLinkToLastBuild: false, keepAll: false, reportDir: 'target/surefire-reports', reportFiles: 'index.html', reportName: 'HTML Report', reportTitles: '', useWrapperFileDirectly: true])
      }
    }
    stage('Docker Image Build'){
      steps {
        echo 'Creating Docker image'
        sh "docker build -t $dockerHubUser/$containerName:$tag --pull --no-cache ."
      }
    }
    stage('Docker Image Scan'){
      steps {
        echo 'Scanning Docker image for vulnerabilities'
        sh "trivy image --severity HIGH,CRITICAL $dockerHubUser/$containerName:$tag"
      }
    }
    stage('Check Docker Image in DockerHub'){
      steps {
        script {
          def imageExists = sh(script: "docker pull $dockerHubUser/$containerName:$tag > /dev/null && echo 'success' || echo 'failed'", returnStdout: true).trim()
          if (imageExists == 'success') {
            error("Image $dockerHubUser/$containerName:$tag already exists in DockerHub. Process will not proceed.")
          } else {
            echo "Image $dockerHubUser/$containerName:$tag does not exist yet in DockerHub. Proceeding to the next stage."
          }
        }
      }
    }
    stage('Publishing Image to DockerHub'){
      steps {
        echo 'Pushing the docker image to DockerHub'
        withCredentials([usernamePassword(credentialsId: 'ERCLI-DockerHub-Credentials', usernameVariable: 'dockerUsername', passwordVariable: 'dockerPassword')]) {
          sh "docker login -u $dockerUsername -p $dockerPassword"
          sh "docker push $dockerUsername/$containerName:$tag"
          echo "Image push complete"
        }
      }
    }
    stage('Deleting Local Docker Image'){
      steps {
        echo 'Deleting the docker image from local machine'
        sh "docker rmi $dockerHubUser/$containerName:$tag"
        echo "Image deletion complete"
      }
    }
    stage('Terraform Initialization & Planning') {
      steps {
        echo 'Fetching files from repository'
        sh "cp -r ${env.WORKSPACE}/*.{tf,yaml} $workingDir"
		echo sh(script: 'ls -lrt', returnStdout: true).trim()
        echo 'Initializing Terraform'
        sh "terraform -chdir=$workingDir init"
		echo 'Terraform Planning'
		sh "terraform -chdir=$workingDir plan"
        echo 'Terraform Initialization complete'
        }
    }
    stage('Terraform Application') {
      steps {
        echo 'Applying Terraform configuration'
        sh "terraform -chdir=$workingDir apply --auto-approve"
        echo 'Terraform apply complete'
        }
    }
  }
}
