pipeline {
    agent any

    parameters {
        choice(
            name: 'TARGET_ENV',
            choices: ['dev', 'qa', 'prod'],
            description: 'GitOps environment to update'
        )
    }

    environment {
        IMAGE_NAME = 'vladxgx/hello-newapp'
        IMAGE_TAG = "${BUILD_NUMBER}"
        DOCKERHUB_CREDENTIALS = credentials('dockerhub-credentials')
        GITHUB_TOKEN = credentials('github-token')
        SLACK_WEBHOOK_URL = credentials('slack-webhook-url')
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Parallel Checks') {
            parallel {
                stage('Lint') {
                    steps {
                        sh '''
                            echo "Running mocked lint check"
                            python -m py_compile app.py
                        '''
                    }
                }

                stage('Security Scan') {
                    steps {
                        sh '''
                            echo "Running mocked security scan"
                            test -s requirements.txt
                            test -s Dockerfile
                        '''
                    }
                }
            }
        }

        stage('Docker Build') {
            steps {
                sh 'docker build -t "${IMAGE_NAME}:${IMAGE_TAG}" .'
            }
        }

        stage('Docker Push') {
            steps {
                sh '''
                    echo "$DOCKERHUB_CREDENTIALS_PSW" |
                        docker login -u "$DOCKERHUB_CREDENTIALS_USR" --password-stdin
                    docker push "${IMAGE_NAME}:${IMAGE_TAG}"
                '''
            }
        }

        stage('Helm Template') {
            steps {
                sh '''
                    helm template hello-newapp ./helmchart/hello-newapp \
                        --set image.repository="$IMAGE_NAME" \
                        --set image.tag="$IMAGE_TAG" \
                        > devops-template.yaml
                '''
            }
        }

        stage('Update GitOps Repo') {
            steps {
                sh '''
                    rm -rf argo-git-ops
                    git clone https://github.com/Vladxgx/argo-git-ops.git
                    mkdir -p "argo-git-ops/$TARGET_ENV"
                    cp devops-template.yaml "argo-git-ops/$TARGET_ENV/devops-template.yaml"

                    cd argo-git-ops
                    git config user.name "Jenkins"
                    git config user.email "jenkins@local"
                    git add "$TARGET_ENV/devops-template.yaml"

                    if git diff --cached --quiet; then
                        echo "GitOps manifest is already up to date"
                    else
                        git commit -m "Deploy hello-newapp ${IMAGE_TAG} to ${TARGET_ENV}"
                        set +x
                        git remote set-url origin \
                            "https://x-access-token:${GITHUB_TOKEN}@github.com/Vladxgx/argo-git-ops.git"
                        git push origin HEAD:main
                    fi
                '''
            }
        }
    }

    post {
        success {
            sh '''
                curl --fail --silent --show-error \
                    -X POST \
                    -H 'Content-Type: application/json' \
                    --data "{\"text\":\"SUCCESS: ${JOB_NAME} #${BUILD_NUMBER} deployed ${IMAGE_NAME}:${IMAGE_TAG} to ${TARGET_ENV}\"}" \
                    "$SLACK_WEBHOOK_URL"
            '''
        }

        failure {
            sh '''
                curl --fail --silent --show-error \
                    -X POST \
                    -H 'Content-Type: application/json' \
                    --data "{\"text\":\"FAILURE: ${JOB_NAME} #${BUILD_NUMBER} for ${IMAGE_NAME}:${IMAGE_TAG} in ${TARGET_ENV}. See ${BUILD_URL}\"}" \
                    "$SLACK_WEBHOOK_URL"
            '''
        }
    }
}
