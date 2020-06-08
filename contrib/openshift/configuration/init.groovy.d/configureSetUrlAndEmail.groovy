#!groovy

// imports
import jenkins.model.Jenkins
import jenkins.model.JenkinsLocationConfiguration

// parameters
def env = System.getenv()

def jenkinsParameters = [
  email:  'Jenkins <jenkins@ah.nl>',
  url:    'https://' + env['JENKINS_SERVICE_NAME'].toLowerCase() + '-' + env['OPENSHIFT_BUILD_NAMESPACE'] + '.openshift.ah.nl/'
]

// get Jenkins location configuration
def jenkinsLocationConfiguration = JenkinsLocationConfiguration.get()

// set Jenkins URL
jenkinsLocationConfiguration.setUrl(jenkinsParameters.url)

// set Jenkins admin email address
jenkinsLocationConfiguration.setAdminAddress(jenkinsParameters.email)

// save current Jenkins state to disk
jenkinsLocationConfiguration.save()

//E-mail Server
def instance = Jenkins.getInstance()
def mailServer = instance.getDescriptor("hudson.tasks.Mailer")

mailServer.setSmtpHost("mail.ah.nl")
mailServer.setSmtpPort("25")
mailServer.setCharset("UTF-8")
instance.save()
