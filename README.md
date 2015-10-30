# IBM Watson Speech QA for iOS
"IBM Watson Speech QA for iOS" is a native iOS app that creates a voice driven app experience using the [Speech to Text][watson_stt_url] and [Question &amp; Answer][watson_qa_url] services, with operational analytics powered by the [Mobile Client Access][ama_url] service on [IBM Bluemix][bluemix_signup_url]. The native iOS app allows you to ask Watson questions in spoken language, and receive textual responses based on the [Watson QA Healthcare data set][watson_healthcare_url].

This app is meant to serve as a demo to showcase how you could integrate IBM Watson, IBM Bluemix, or IBM MobileFirst solutions into your mobile applications.

You can see a preview of this app in action and a brieft walkthrough of the code in the following video preview: 

[https://youtu.be/rywvlomIzIg][youtube_video_snip_url]

[<img src="./github_content/video.jpg" width="100%">][youtube_video_snip_url]<br/>

---

### Recent Changes

#### 10/30/15
1. Update to use Watson Developer Cloud Speech SDK for iOS for streaming audio to Speech to Text Service
2. Updated instructions to use new/renamed Mobile Client Access service

---

### Bluemix Services Used

1. [Mobile Client Access][ama_url] - Capture analytics and logs from mobile apps running on devices
2. [Speech to Text][watson_stt_url] - Convert spoken audio into text
3. [Question &amp; Answer][watson_qa_url] - Natural language search 

### Architecture Diagram

This an architectural overview of the components that make this app run.   

<img src="./github_content/architecture.jpg" width="100%">
	
The mobile application connects to the [Mobile Client Access][ama_url] service to provide operational analytics (usage, devices, network utilization) and remote log collection from the client app on the mobile devices.

The app communicates to the [Speech to Text][watson_stt_url] and [Question &amp; Answer][watson_qa_url] servies through the Node.js middelware tier.  

For the Speech To Text interaction, the app streams audio from the local device to the Watson Speech To Text Service using the [Watson Speech iOS SDK][watson_ios_sdk].  

For the QA service, the app makes an HTTP GET request (containing the query string) to the Node.js server, which delegates to the Watson QA natural language processing service to return search results. The Node.js tier then formats the respons JSON object and returns the query to the mobile app. 

### Order of Operations

The provide interactive feedback to the end user of the mobile application, the Speech To Text and QA service requests have been separated out into separate service methods.  They could be combined into a single query/response, however, the decision was made to keep them separate so that feedback could be provided to the user as the search is taking place.  

The general flow is outlined below:

<img src="./github_content/flow.jpg" width="100%">

<br/><br/>

---------

## Setting up the App

This app consists of two parts: a native iOS app (Xcode project) and the backend services running on Bluemix.  Both of these services need to be configured for the application to work properly.

### Setting Up The Bluemix Backend

There are two ways that you can configure the back-end Bluemix application.  You can either use the web-based GUI or you can use the command line interface.  These instructions will walk through setting up the Node.js backend applicaiton using the [Cloud Foundry Command Line Interface][cloud_foundry_url].  

1. Create a Bluemix Account

    [Sign up][bluemix_signup_url] for Bluemix, or use an existing account.

2. Download and install the [Cloud-foundry CLI][cloud_foundry_url] tool

3. Clone the app to your local environment from your terminal using the following command

  ```
  git clone https://github.com/triceam/IBM-Watson-Speech-QA-iOS.git
  ```

4. cd into this newly created directory, then go into the /server directory.

5. Edit the `manifest.yml` file and change the `<application-name>` and `<application-host>` to something unique.

  ```
  ---
	applications:
	- name: iOS-Ask-Watson-App
      framework: node
      runtime: node12
	  memory: 512M
	  instances: 1
	  host: ios-ask-watson-App
	  domain: mybluemix.net
	  services:
	  - askwatson-advanced-mobile-access
	  - askwatson-speech-to-text
	  - askwatson-qa
  ```
  The host you use will determine your application url initially, e.g. `<application-host>.mybluemix.net`.   Remember this, you will need it later.

   *Keep in mind that the app name will need to be unique (you will receive error messages if your selection is not unique).*

6. Connect to Bluemix in the command line tool and follow the prompts to log in.

  ```
  $ cf api https://api.ng.bluemix.net
  $ cf login
  ```

7. Create the Mobile Client Access, Watson QA, and Speech To Text services on Bluemix.

  ```
  $ cf create-service AdvancedMobileAccess Bronze askwatson-advanced-mobile-access
  $ cf create-service question_and_answer question_and_answer_free_plan askwatson-qa
  $ cf create-service speech_to_text standard askwatson-speech-to-text
  ```

8. Push it to Bluemix. This will automatically deploy the back end app and start the Node.js instance.

  ```
  $ cf push
  ```
  
9. Voila! You now have your very own instance up and running on Bluemix.  Next we need to configure the Mobile Client application.

### Setting Up The Mobile App

The native iOS application requires Xcode running on a Mac to compile and deploy on either the iOS Simulator or on a development device.

1. If you do not already have it, download and install [CocoaPods][cocoapods_url].

2. In a terminal window, cd into the /client directory (from your local project directory).

3. Run the *pod install* command to setup the Xcode project and download all dependencies.

  ```
  $ pod install
  ```

4. This will create an Xcode Workspace file.  Open the **DrWatson.xcworkspace** file in Xcode.

5. Open the "**Info.plist**" file.  You need to enter the Bundle Identifier, Backend_Route, and Backend_GUID values that can be obtained from your [Bluemix Dashboard][bluemix_dashboard_url].  Just click on the "Mobile Options" link when viewing the application's dashboard. 

    <img src="./github_content/mobile-options.jpg" width="100%">
    
   * **Bundle Identifier** - You need to set the Bundle Indentifier value to match the bundle ID specified when configuring Mobile Client Access. 
     
     *This is case-sensitive, and MUST exactly match the bundle ID entered in earlier steps.*
   * **Backend_Route** - This is the application route for your Bluemix MCA app.  You can see this value under Mobile Options.
   * **Backend_GUID** - This is the application UID for your Bluemix MCA app.  You can see this value under Mobile Options.
   
    <img src="./github_content/Xcode.jpg" width="100%">

6. Download the [Watson Speech iOS SDK][watson_ios_sdk] and extract the contents of the watsonsdk.framework.zip file.  Copy the extracted watsonsdk.framework into the Xcode project's "Frameworks" directory.

7. Open the ViewController.m file and update lines 36 and 37 to use authentication credentials for your Watson Speech To Text service (these can be found by expanding the "Show Credentials" link on the Speech To Text service on the application's dashboard on Bluemix) 

8. Now you are all set!  Launch the app either on a device or in the iOS Simulator using Xcode.  Tap on the Microphone button and [start asking questions][demo_app_route].  

    <img src="./github_content/app.jpg" >
    
   Once your app is running, you should see the message "You have connected to Bluemix successfully" in the Xcode console.  If you see error messages instead, please double check your bundle ID, app route, and app UID in both the Mobile Client Access service on Bluemix and in the Xcode project. These values are case sensitive and must be identical. 
   
<br/><br/>

---------

### Asking Questions
The Watson API is incredibly powerful, but this sample is designed using only the public healthcare data set, which is trained to only answer [specific kinds of questions][data_coropora_url].

Watson QA data corpora can be customized and created for any data set, however this requires system training and an engagement with IBM. Only limited healthcare and travel copora are available for the free public data sets.

####Need some ideas of what to ask?

Conditional Questions:
* What is X?
* What causes X?
* What is the treatment for X?
* What are the symptoms of X?
* Am I at risk of X?

Procedure Questions:
* What should I expect before X?
* What should I expect after X?

Sample Conditional Questions:
* What are symptoms of Parkinson's disease?
* What is Machado-Joseph Disease?
* What causes Wilson Disease?
* What is the treatment for Autoimmune Hepatitis?
* Am I at risk of a stroke?
* What can I expect before heart surgery?
* What can I expect after a colonoscopy?
* What are the benefits of taking aspirin daily?

General Health Questions:
* What are the benefits of taking aspirin daily?
* Why do I need to get shots?
* How do I know if I have food poisoning?

Action-Related Questions:
* How can I quit smoking?
* What should I do if my child is obese?
* What can I do to get more calcium?

---------

### Troubleshooting

To troubleshoot your the server side of your Bluemix app the main useful source of information is the logs. To see them, run:

  ```
  $ cf logs <application-name> --recent
  ```

### Privacy Notice

The IBM Watson Speech QA - iOS backend Node.js application includes code to track deployments to Bluemix and other Cloud Foundry platforms. The following information is sent to a [Deployment Tracker] [deploy_track_url] service on each deployment:

* Application Name (`application_name`)
* Space ID (`space_id`)
* Application Version (`application_version`)
* Application URIs (`application_uris`)

This data is collected from the `VCAP_APPLICATION` environment variable in IBM Bluemix and other Cloud Foundry platforms. This data is used by IBM to track metrics around deployments of sample applications to IBM Bluemix. Only deployments of sample applications that include code to ping the Deployment Tracker service will be tracked.

### Disabling Deployment Tracking

Deployment tracking can be disabled by removing `require("cf-deployment-tracker-client").track();` from the beginning of the `app.js` main server file.

[bluemix_signup_url]: https://ibm.biz/IBM-Bluemix
[bluemix_dashboard_url]: https://ibm.biz/Bluemix-Dashboard
[cloud_foundry_url]: https://github.com/cloudfoundry/cli
[download_node_url]: https://nodejs.org/download/
[deploy_track_url]: https://github.com/cloudant-labs/deployment-tracker
[cocoapods_url]: https://cocoapods.org/
[demo_app_route]: http://ask-dr-watson.mybluemix.net/
[ama_url]: https://ibm.biz/Bluemix-AdvancedMobileAccess
[watson_qa_url]: https://ibm.biz/Watson-QA
[watson_stt_url]: https://ibm.biz/Watson-STT
[watson_healthcare_url]: http://www.ibm.com/smarterplanet/us/en/ibmwatson/developercloud/doc/qaapi/corpora.shtml#healthcare
[youtube_video_url]: http://www.youtube.com/watch?v=0kedhwC3ikY
[youtube_video_snip_url]: https://ibm.biz/BdXh3E
[data_coropora_url]: http://www.ibm.com/smarterplanet/us/en/ibmwatson/developercloud/doc/qaapi/#corpora
[watson_ios_sdk]: https://github.com/watson-developer-cloud/speech-ios-sdk