


library(googleCloudRunner)
#Firstly you have to set up an env in GCP and Your PC access (02.help) 




########################
#1 we can create YAML manually
#INFO: we can run by opening the browser (launch_browser=TRUE). We can copy the link if we want to run in another account
# https://console.cloud.google.com/cloud-build/builds
b1 <- cr_build("10 cloudbuildTest.yaml")

########################
#2 we can wait for end of running in GCP
# https://console.cloud.google.com/cloud-build/builds
b2 <- cr_build("10 cloudbuildTest.yaml", launch_browser = FALSE)
b3 <- cr_build_wait(b2)

#######################
#3 we can run and schedule
# https://console.cloud.google.com/cloudscheduler
itworks <- cr_build("10 cloudbuildTest.yaml", launch_browser = FALSE)
cr_schedule("20 * * * *", name="deploy-z-R-schedule1",httpTarget = cr_build_schedule_http(itworks))







#############################################################

######################
#4. Now we can create our own docker image in GCP registry based on Dockerfile (included in R project)
#INFO: You have to delete '..tar.gz' file and 'deploy' catalog after each deployment! 
#building process: https://console.cloud.google.com/cloud-build/builds/
#result image: https://console.cloud.google.com/gcr
cr_deploy_docker("./",image_name ='mytidyverse',tag="latest")



#5. Run R code on private docker and copy the result csv into gooogle storage (in YAML is my google storage)
#INFO: we can do that also by artifacts
#CONFIG:
#gs://gcp-r-bucket/auto/ is my backet for data
itworks <- cr_build("11 cloudbuildCopyCsv.yaml", launch_browser = FALSE)
cr_schedule("20 * * * *", name="deploy-from-R-schedule2",httpTarget = cr_build_schedule_http(itworks))









#############################################################
# 6. We can do that without YAML predefined file.  We can create yaml file by cr_build_yaml
# INFO: 
# gs://gcp-r-bucket/auto is my backet for data
# gcr.io/szkolachmury-kurs-gcp/mytidyverse:latest is my image of docker

# We can:
# create it by R code
yaml<-cr_build_yaml(
  steps = c(
    cr_buildstep_r("20 forYamlCOVIDpoland.R"
                   , name="gcr.io/szkolachmury-kurs-gcp/mytidyverse:latest"
                   , id='run R script'),
    cr_buildstep( name="gcr.io/cloud-builders/gsutil",
                  args = c("cp","/workspace/*.csv","gs://gcp-r-bucket/auto"),
                  id = "copy throw gsutil")
    )
  )
# save object into *.yaml file (eg. for running on other env)
cr_build_write(yaml, file = "cloudbuild_write.yaml")
# build it, and automatically run in GCP
# https://console.cloud.google.com/cloud-build/builds
build <- cr_build(yaml, launch_browser = FALSE)
# and schedule it
# https://console.cloud.google.com/cloudscheduler
cr_schedule("20 * * * *", name="testdeploy-z-R-zrzut-GOV-koronawirus",httpTarget = cr_build_schedule_http(build))









#############################################################
# 7. We can export csv into BigQuery also:
# scrapping of Polish gov site.
#INFO: 
# gs://gcp-r-bucket/auto is my backet for data
# automatEU.coronawirus_gov_pl is my dataset in bq
# /workspace/out.csv is an output csv file from 20 forYamlCOVIDpoland.R script
# https://console.cloud.google.com/gcr/images/cloud-builders
yaml<-cr_build_yaml(
  steps = c(
    cr_buildstep_r("20 forYamlCOVIDpoland.R"
                   , name="gcr.io/szkolachmury-kurs-gcp/mytidyverse:latest"
                   , id='run R script'
                   ),
    cr_buildstep( name="gcr.io/cloud-builders/gsutil",
                  args = c("cp","/workspace/*.csv","gs://gcp-r-bucket/auto"),
                  id = "copy files by gsutil"),
    cr_buildstep(   id = "load BigQuery",
                    name = "gcr.io/cloud-builders/gcloud",
                    entrypoint = "bq",
                    args = c("--location=EU",
                             "load",
                             "--autodetect",
                             "--source_format=CSV",
                             "automatEU.coronawirus_gov_pl",
                             "/workspace/out.csv"),
                    env='CLOUDSDK_COMPUTE_ZONE=eu-east4-b'
                  )
  )
)
build <- cr_build_make(yaml)
cr_schedule("23 * * * *", name="deploy-z-R-zrzutBQ-GOV-koronawirus3",httpTarget = cr_build_schedule_http(build))







#############################################################
# 8. scrapping of worldometer site
yaml<-cr_build_yaml(
  steps = c(
    cr_buildstep_r("21 forYamlWorldometers.R"
                   , name="gcr.io/szkolachmury-kurs-gcp/mytidyverse:latest"
                   , id='Uruchomienie skryptu R'
                   ,dir = "build"
    ),
    cr_buildstep( name="gcr.io/cloud-builders/gsutil",
                  args = c("cp","/workspace/build/*.csv","gs://gcp-r-bucket/auto/worldometers"),
                  id = "kopiowanie CSV przez gsutil"),
    cr_buildstep( name="gcr.io/cloud-builders/gsutil",
                  args = c("cp","/workspace/build/*.Rdata","gs://gcp-r-bucket/auto/worldometers"),
                  id = "kopiowanie Rdata przez gsutil"),
    
    
    cr_buildstep(   id = "load BigQuery",
                    name = "gcr.io/cloud-builders/gcloud",
                    entrypoint = "bq",
                    args = c("--location=EU",
                             "load",
                             "--autodetect",
                             "--source_format=CSV",
                             "automatEU.coronawirus_worldometers3",
                             "/workspace/build/outToday.csv"),
                    env='CLOUDSDK_COMPUTE_ZONE=eu-east4-b'
    )
  )
)
build <- cr_build_make(yaml)
cr_schedule("25 * * * *", name="deploy-z-R-zrzutBQ-worldometers",httpTarget = cr_build_schedule_http(build))




