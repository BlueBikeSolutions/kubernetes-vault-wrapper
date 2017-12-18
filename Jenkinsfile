def toBuild = [
  [image: "rabbitmq", tag: "3.6-management-alpine"],
]

def steps = toBuild.collectEntries {
  ["running ${it.image}:${it.tag}": stepsFor(it.image, it.tag)]
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
        withEnv(["DOCKER_IMAGE=696234038582.dkr.ecr.ap-southeast-2.amazonaws.com/services/${image}"]) {
          stage("[${image}:${tag}] Docker image") {
            sh """
            set -e
            echo FROM ${image}:${tag} > "${image}-${tag}.Dockerfile"
            cat body.Dockerfile >> "${image}-${tag}.Dockerfile"
            echo ENTRYPOINT $(docker inspect -f '{{ .Config.Entrypoint | json }}' "${image}:${tag}") >> "${image}-${tag}.Dockerfile"
            echo CMD $(docker inspect -f '{{ .Config.Cmd | json }}' "${image}:${tag}") >> "${image}-${tag}.Dockerfile"

            docker build \
              -t \$DOCKER_IMAGE:${tag} \
              -f "${image}-${tag}.Dockerfile" \
              .
            docker push \$DOCKER_IMAGE:${tag}
            """
          }
        }
      }
    }
  }
}
