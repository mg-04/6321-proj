#!/bin/bash

#export CDS_Netlisting_Mode=Analog
#
## tsmc65 installation path
#export TSMC65_INST_DIR=/courses/ee6350/pdk2023/T-N65-CM-SP-018-K3_MOM/Base_PDK/PDK_CRN65GP_v1.0c_official_IC61_20101010
#
#export CDSHOME=/tools/cadence/IC618.270
#
## Calibre setup
#export TSMC65_LPE_RULE_DIR=/courses/ee6350/pdk2023/T-N65-CM-SP-018-K3_MOM/Base_PDK/PDK_CRN65GP_v1.0c_official_IC61_20101010/Calibre/rcx/
#
export WORKSPACEHOME=/courses/ee6350/shared/
export CALIBRE_RUNDIR=~/calibre_rundir/
#
## Digital flow setup
#export PDK_DIGITAL=/courses/ee6350/pdk2023/T-N65-CM-SP-018-K3_MOM/digital
#export PDK_PATH=/courses/ee6350/pdk2023/T-N65-CM-SP-018-K3_MOM/Base_PDK/PDK_CRN65GP_v1.0c_official_IC61_20101010/
#
#umask 007

# start virtuoso
virtuoso &
