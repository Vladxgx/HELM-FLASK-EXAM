@Library('mySharedLib') _

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
                script {
                    sourceControl.gitStatus()
                }
            }
        }

        stage('Parallel Checks') {
            parallel {
                stage('Flake8 Lint') {
                    steps {
                        script {
                            tests.flake8Test()
                        }
                    }
                }

                stage('Bandit Scan') {
                    steps {
                        script {
                            tests.banditTest()
                        }
                    }
                }
            }
        }

        stage('Docker Build') {
            steps {
                script {
                    dockering.imageBuild()
                }
            }
        }

        stage('Trivy Image Scan') {
            steps {
                script {
                    tests.trivyTest()
                }
            }
        }

        stage('Docker Push') {
            steps {
                sh '''
                    echo "$DOCKERHUB_CREDENTIALS_PSW" |
                        docker login -u "$DOCKERHUB_CREDENTIALS_USR" --password-stdin
                '''
                script {
                    dockering.imagePush()
                }
            }
        }

        stage('Helm Template') {
            steps {
                sh '''
                    echo "Downloading Helm"
                    mkdir -p .tools
                    curl --fail --silent --show-error --location \
                        https://get.helm.sh/helm-v3.15.4-linux-amd64.tar.gz \
                        --output .tools/helm.tar.gz
                    tar -xzf .tools/helm.tar.gz -C .tools

                    echo "Rendering Helm template"
                    .tools/linux-amd64/helm template hello-newapp ./helmchart/hello-newapp \
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

        stage('Slack Success Notification') {
            steps {
                sh '''
                    MESSAGE="Jenkins pipeline succeeded\\nJob: $JOB_NAME\\nBuild: #$BUILD_NUMBER\\nEnvironment: $TARGET_ENV\\nImage: $IMAGE_NAME:$IMAGE_TAG"
                    PAYLOAD="{\\"text\\":\\"$MESSAGE\\"}"
                    curl --fail --silent --show-error \
                        -X POST \
                        -H 'Content-Type: application/json' \
                        --data "$PAYLOAD" \
                        "$SLACK_WEBHOOK_URL"
                '''
            }
        }
    }

    post {
        failure {
            script {
                stage('Slack Failure Notification') {
                    sh '''
                        MESSAGE="Jenkins pipeline failed\\nJob: $JOB_NAME\\nBuild: #$BUILD_NUMBER\\nEnvironment: $TARGET_ENV\\nImage: $IMAGE_NAME:$IMAGE_TAG\\nURL: $BUILD_URL"
                        PAYLOAD="{\\"text\\":\\"$MESSAGE\\"}"
                        curl --fail --silent --show-error \
                            -X POST \
                            -H 'Content-Type: application/json' \
                            --data "$PAYLOAD" \
                            "$SLACK_WEBHOOK_URL"
                    '''
                }
            }
        }
    }
}
