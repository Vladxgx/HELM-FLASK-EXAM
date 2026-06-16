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
                            python3 -m py_compile app.py || python -m py_compile app.py
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
                    if command -v helm >/dev/null 2>&1; then
                        HELM_BIN=helm
                    else
                        mkdir -p .tools
                        case "$(uname -m)" in
                            x86_64) HELM_ARCH=amd64 ;;
                            aarch64|arm64) HELM_ARCH=arm64 ;;
                            *) echo "Unsupported architecture: $(uname -m)" && exit 1 ;;
                        esac

                        curl --fail --silent --show-error --location \
                            "https://get.helm.sh/helm-v3.15.4-linux-${HELM_ARCH}.tar.gz" \
                            --output .tools/helm.tar.gz
                        tar -xzf .tools/helm.tar.gz -C .tools
                        HELM_BIN="$PWD/.tools/linux-${HELM_ARCH}/helm"
                    fi

                    "$HELM_BIN" template hello-newapp ./helmchart/hello-newapp \
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
                payload=$(printf '{"text":"SUCCESS: %s #%s deployed %s:%s to %s"}' \
                    "$JOB_NAME" "$BUILD_NUMBER" "$IMAGE_NAME" "$IMAGE_TAG" "$TARGET_ENV")
                curl --fail --silent --show-error \
                    -X POST \
                    -H 'Content-Type: application/json' \
                    --data "$payload" \
                    "$SLACK_WEBHOOK_URL"
            '''
        }

        failure {
            sh '''
                payload=$(printf '{"text":"FAILURE: %s #%s for %s:%s in %s. See %s"}' \
                    "$JOB_NAME" "$BUILD_NUMBER" "$IMAGE_NAME" "$IMAGE_TAG" "$TARGET_ENV" "$BUILD_URL")
                curl --fail --silent --show-error \
                    -X POST \
                    -H 'Content-Type: application/json' \
                    --data "$payload" \
                    "$SLACK_WEBHOOK_URL"
            '''
        }
    }
}
