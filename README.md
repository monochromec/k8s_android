# k8s_android

This repository contains the code and supplementary information for the installation and configuration of a minimal
one-node cluster on an Android device (more details in a [presentation](https://programm.froscon.org/2023/events/2930.html), in German).

Upon successful installation and configuration, you will be able to deploy a sample application in the shape of a tiny webserver
running on pods in a VM on an Android device. 

A brief desription of the files and their purpose:

- environment.md: A step-by-step guide for the installation and configuration of the infrastructure. More details in this [presentation](https://www.tuebix.org/2023/programm/50-neues-vom-spielplatz-kubernetes-auf-deinem-smartphone/) (in German)
- main.go, go.*: a tiny webserver for pod deployment, losely based on [this presentation](https://events.opensuse.org/conferences/oSC23/program/proposals/4145)
- depl.yml and svc.yml: k8s deployment and service definition for the webserver
- build.sh and Dockerfile: a script for a multi-stage build using the Dockerfile; the resulting image is pushed to a local repository (cf. depl.yml) 
- adb_fwd.sh: (Reverse) Port forwards for host access via adb

Feedback via mail or GH issue is welcome!
