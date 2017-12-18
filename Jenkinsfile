def toBuild = [
  [image: "rabbitmq", tag: "3.6-management-alpine"],
]

def steps = toBuild.collectEntries {
  ["${it.image}:${it.tag}": stepsFor(it.image, it.tag)]
}

parallel steps


def stepsFor(image, tag) {
  return {
    node('master') {
      ansiColor('xterm') {
        stage("[${image}:${tag}] Cloning Repo") {
          git credentialsId: 'ghsignin', url: 'https://github.com/BlueBikeSolutions/kubernetes-vault-wrapper'
          checkout scm
          echo "\u2600 BUILD_URL=${env.BUILD_URL}"
          def workspace = pwd()
          echo "\u2600 workspace=${workspace}"
        }
        stage("[${image}:${tag}] Docker login") {
          sh '''
          eval "$(docker run --rm awscli ecr get-login --no-include-email --region ap-southeast-2)"
          '''
        }
        withEnv([
          "DOCKER_IMAGE=696234038582.dkr.ecr.ap-southeast-2.amazonaws.com/services/${image}",
          "DOCKER_TAG=${tag}",
          "DOCKER_IMAGE_TAG=${image}:${tag}",
          "DOCKER_FILENAME=${image}-${tag}.Dockerfile",
        ]) {
          stage("[${image}:${tag}] Docker image") {
            sh '''
            set -e

            docker pull $DOCKER_IMAGE_TAG

            echo FROM $DOCKER_IMAGE_TAG > "$DOCKER_FILENAME"
            cat body.Dockerfile >> "$DOCKER_FILENAME"
            echo ENTRYPOINT $(docker inspect -f '{{ .Config.Entrypoint | json }}' "$DOCKER_IMAGE_TAG") >> "$DOCKER_FILENAME"
            echo CMD $(docker inspect -f '{{ .Config.Cmd | json }}' "$DOCKER_IMAGE_TAG") >> "$DOCKER_FILENAME"

            docker build \
              -t $DOCKER_IMAGE:$DOCKER_TAG \
              -f "$DOCKER_FILENAME" \
              .
            docker push $DOCKER_IMAGE:$DOCKER_TAG
            '''
          }
        }
      }
    }
  }
}
