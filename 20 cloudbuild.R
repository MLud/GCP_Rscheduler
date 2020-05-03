





library(googleCloudRunner)

########################1
#odpalenie przez samoczynne uruchomienie przeglądarki (launch_browser=TRUE). Można skopiować link jeśli jest inne konto
b1 <- cr_build("19 cloudbuild.yaml")




########################2
#info na temat zakończenia deploymentu
b2 <- cr_build("19 cloudbuild.yaml", launch_browser = FALSE)
b3 <- cr_build_wait(b2)
#zapisz obiekt do yaml
cr_build_write(b3, file = "cloudbuild_write.yaml")


########################3 pieknie działa
#można uruchomić scheduler demo
itworks <- cr_build("19 cloudbuild.yaml", launch_browser = FALSE)
cr_schedule("20 * * * *", name="deploy-z-R-schedule11",httpTarget = cr_build_schedule_http(itworks))



#############################################################
#uruchom kod i przekopiuj rezultat na bucket za pomocą gsutil
itworks <- cr_build("18 cloudbuild2.yaml", launch_browser = FALSE)
cr_schedule("20 * * * *", name="deploy-z-R-schedule11",httpTarget = cr_build_schedule_http(itworks))




#############################################################
#stwórz YAML ze skryptu R, zbuduj dockera i przekopiuj rezultat na bucket za pomocą gsutil
yaml<-cr_build_yaml(
  steps = c(
    cr_buildstep_r("16 forYaml.R"
                   , name="gcr.io/szkolachmury-kurs-gcp/dockerfile:1"
                   , id='Uruchomienie skryptu R'),
    cr_buildstep( name="gcr.io/cloud-builders/gsutil",
                  args = c("cp","/workspace/*.csv","gs://gcp-r-bucket/auto"),
                  id = "kopiowanie przez gsutil")
    )
  )
build <- cr_build(yaml, launch_browser = FALSE)
cr_schedule("20 * * * *", name="deploy-z-R-zrzut-GOV-koronawirus",httpTarget = cr_build_schedule_http(build))


#############################################################
#stwórz YAML ze skryptu R, zbuduj dockera i wrzuć dane na bq
yaml<-cr_build_yaml(
  steps = c(
    cr_buildstep_r("16 forYaml.R"
                   , name="gcr.io/szkolachmury-kurs-gcp/dockerfile:1"
                   , id='Uruchomienie skryptu R'
                   ),
    cr_buildstep( name="gcr.io/cloud-builders/gsutil",
                  args = c("cp","/workspace/*.csv","gs://gcp-r-bucket/auto"),
                  id = "kopiowanie przez gsutil"),
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
#build <- cr_build(yaml, launch_browser = FALSE) #można przetestować czy uruchamia się cloud build
build <- cr_build_make(yaml)
cr_schedule("23 * * * *", name="deploy-z-R-zrzutBQ-GOV-koronawirus3",httpTarget = cr_build_schedule_http(build))






#############################################################
# zrzut danych w worldometer
#stwórz YAML ze skryptu R, zbuduj dockera i wrzuć dane na bq
yaml<-cr_build_yaml(
  steps = c(
    cr_buildstep_r("14 forYamlWorldometers.R"
                   , name="gcr.io/szkolachmury-kurs-gcp/dockerfile:1"
                   , id='Uruchomienie skryptu R'
                   ,dir = "build"
    ),
    cr_buildstep( name="gcr.io/cloud-builders/gsutil",
                  args = c("cp","/workspace/build/*.csv","gs://gcp-r-bucket/auto/worldometers"),
                  id = "kopiowanie przez gsutil"),
    cr_buildstep(   id = "load BigQuery",
                    name = "gcr.io/cloud-builders/gcloud",
                    entrypoint = "bq",
                    args = c("--location=EU",
                             "load",
                             "--autodetect",
                             "--source_format=CSV",
                             "automatEU.coronawirus_worldometers2",
                             "/workspace/build/outToday.csv"),
                    env='CLOUDSDK_COMPUTE_ZONE=eu-east4-b'
    )
  )
)
build <- cr_build_make(yaml)
cr_schedule("25 * * * *", name="deploy-z-R-zrzutBQ-worldometers",httpTarget = cr_build_schedule_http(build))




