pipeline {
    agent any

    stages {
        stage('Build') {
            steps {
                echo 'Building..'
                sh '''
                    python3 -m venv project-venv
                    . ./project-venv/bin/activate
                    pip -V
                    pip list
                '''
            }
        }
        stage('Test') {
            steps {
                echo 'Testing..'
                sh 'python3 test.py'
            }
        }
        stage('Deploy') {
            steps {
                echo 'Deploying....'
            }
        }
    }
}
