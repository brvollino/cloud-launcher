pipeline {
    agent any
     parameters {
        booleanParam(name: 'APPLY', defaultValue: false, description: 'Apply the changes. Otherwise it will just "plan".')
    }
    stages {
        stage('Terraform init') {
            steps {
                sh 'terraform init'
            }
        }
        stage('Terraform plan') {
            environment {
                AWS_ACCESS_KEY = credentials('aws-access-credential')
            }
            steps {
                sh 'terraform plan -var=\"access_key=${env.AWS_ACCESS_KEY_USR}\" -var=\"secret_key=${env.AWS_ACCESS_KEY_PSW}\"'
            }
        }
        stage('Terraform apply') {
            when {
                expression { params.APPLY }
            }
            environment {
                AWS_ACCESS_KEY = credentials('aws-access-credential')
            }
            steps {
                sh 'printenv'
                sh 'terraform plan -var=\"access_key=${env.AWS_ACCESS_KEY_USR}\" -var=\"secret_key=${env.AWS_ACCESS_KEY_PSW}\"'
            }
        }
    }
}