node {

	catchError {

		stage('CheckOut') {
			checkout scm
			sh 'git submodule update --init'
		}

		stage('Build Linux') {
			docker.image('amarillion/alleg5-dallegro:latest').inside() {		
				// dub will try to write to `$HOME/.dub`, as user `jenkins`
				// make sure $HOME maps to the workspace or we'll get a permission denied here. 
				withEnv(['HOME=.']) {
					sh "dub -v build"

					// TODO: tests fail with error 'Source file '/home/martijn/prg/gamedev/allegro-shader-toy/dtwist/src/helix/allegro/audiostream.d' not found in any import path.'
					// sh "dub -v test"
				}
			}
		}

	}

//	mailIfStatusChanged env.EMAIL_RECIPIENTS
	mailIfStatusChanged "mvaniersel@gmail.com"
}

//see: https://github.com/triologygmbh/jenkinsfile/blob/4b-scripted/Jenkinsfile
def mailIfStatusChanged(String recipients) {
    
	// Also send "back to normal" emails. Mailer seems to check build result, but SUCCESS is not set at this point.
    if (currentBuild.currentResult == 'SUCCESS') {
        currentBuild.result = 'SUCCESS'
    }
    step([$class: 'Mailer', recipients: recipients])
}
