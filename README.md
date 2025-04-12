---

# 📦 Blog Application - CI/CD Pipeline with Jenkins & Kubernetes

This project implements a comprehensive CI/CD pipeline for a Java-based blog application. The pipeline automates the build, test, scan, package, and deployment processes using Jenkins. The application is containerized with Docker and deployed to a Kubernetes cluster provisioned using Terraform.

---

## ⚙️ Project Components

This repository includes:

- Blog application source code (`Java`)
- `Jenkinsfile` defining CI/CD stages
- `Dockerfile` for containerizing the application
- Kubernetes manifest files for application deployment

---

## 🧱 Infrastructure Setup

### ✅ Provisioning

- **Cloud Platform**: AWS
- **Infrastructure as Code**: Terraform (used to provision EC2 instances and Kubernetes cluster)
- **Kubernetes Setup**: `kubeadm` on:
  - 1 Master Node
  - 2 Worker Nodes

### ✅ VMs and Roles

| VM                  | Role                         |
|---------------------|------------------------------|
| `jenkins-server`    | CI/CD pipeline orchestration |
| `sonarqube-server`  | Code quality analysis        |
| `nexus-server`      | Artifact repository          |
| `monitoring-server` | Prometheus & Grafana         |
| `k8s-master`        | Kubernetes master node       |
| `k8s-worker-1/2`    | Kubernetes worker nodes      |

---

## 🛠 Tools & Versions

| Tool           | Purpose                              | Version     |
|----------------|--------------------------------------|-------------|
| Jenkins        | Pipeline orchestration               | Latest LTS  |
| Maven          | Build tool for Java                  | 3.9.8       |
| SonarQube      | Static code analysis                 | Community LTS |
| Trivy          | Vulnerability scanner                | Latest      |
| Nexus          | Artifact storage                     | latest      |
| Docker         | Containerization                     | Latest CE   |
| Kubernetes     | Container orchestration              | 1.29        |
| Prometheus     | Metrics collection                   | Latest      |
| Grafana        | Monitoring dashboard                 | Latest      |
| Terraform      | EKS cluster management               | 1.11.4      |
| SonarScanner	 | Static code analysis	                | 6.1.0.4477	|
| JDK	           | Java Development Kit                 | 17.0.11+9   |

---

## 🔁 CI/CD Pipeline Stages (`Jenkinsfile`)

```groovy
pipeline {
  agent any
  tools {
    jdk 'jdk17'
    maven 'maven3'
  }
  environment {
    SCANNER_HOME = tool 'sonar-scanner'
  }

  stages {
    stage('Checkout') {
      steps {
        git branch: 'main', credentialsId: 'git-cred', url: 'https://github.com/Kratos-89/Corporate-CICD-Project.git'
      }
    }

    stage('Compile') {
      steps {
        sh 'mvn compile'
      }
    }

    stage('Unit Test') {
      steps {
        sh 'mvn test'
      }
    }

    stage('SonarQube Analysis') {
      steps {
        withSonarQubeEnv('sonar') {
          sh '$SCANNER_HOME/bin/sonar-scanner -Dsonar.projectKey=blog-app -Dsonar.java.binaries=.'
        }
      }
    }

    stage('Trivy Filesystem Scan') {
      steps {
        sh 'trivy fs --format table -o trivy-fs-report.html .'
      }
    }

    stage('Package') {
      steps {
        sh 'mvn package'
      }
    }

    stage('Deploy Artifact to Nexus') {
      steps {
        sh 'mvn deploy'
      }
    }

    stage('Docker Build') {
      steps {
        sh 'docker build -t <docker-username>/blog-app:latest .'
      }
    }

    stage('Trivy Image Scan') {
      steps {
        sh 'trivy image <docker-username>/blog-app:latest --format table -o trivy-image-report.html'
      }
    }

    stage('Push Docker Image') {
      steps {
        sh 'docker push <docker-username>/blog-app:latest'
      }
    }

    stage('Kubernetes Deploy') {
      steps {
        withKubeConfig(credentialsId: 'k8s-creds') {
          sh 'kubectl apply -f deployment-service.yaml'
        }
      }
    }
  }

  post {
    always {
      emailext(
        subject: "${env.JOB_NAME} - Build #${env.BUILD_NUMBER}",
        body: "Build ${env.BUILD_NUMBER} completed. Check console for more details.",
        to: 'your-email@example.com',
        attachmentsPattern: 'trivy-*.html',
        mimeType: 'text/html'
      )
    }
  }
}
```

---

## 📄 Kubernetes Configuration

### `deployment-service.yaml` includes:

- **Deployment**:
  - Docker image: `<docker-username>/blog-app:latest`
  - Container Port: 8080
  - Replicas: 2
- **Service**:
  - Type: NodePort / LoadBalancer
  - Port: 80 → TargetPort: 8080

---

## 🔍 Monitoring Setup

- **Prometheus** scrapes metrics from:
  - Kubernetes nodes
  - Application endpoints
  - Blackbox exporters
- **Grafana** imports dashboards for:
  - Node health
  - Container resource usage
  - Application uptime

---

## 🔐 Security Configs

- Trivy scanning for both filesystem and image-level vulnerabilities
- SonarQube reports for code smells, bugs, and vulnerabilities
- Jenkins credentials store used for Git, Docker, Nexus, and Kubernetes secrets

---

## 📌 Notes

- All credentials (GitHub token, DockerHub creds, Sonar token, Nexus creds) are managed using **Jenkins Credentials Manager**.
- Terraform modules are kept separate for clean IaC separation.
- The image tag in the deployment.yaml is automatically updated once any change is situated.

---

```
