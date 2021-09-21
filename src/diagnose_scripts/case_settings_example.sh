#!/bin/bash

diag_prefix="some_prefix"

concat_beg_year=1
concat_end_year=2

diag_beg_year=2
diag_end_year=2

ptasks=4
sim_data_dir="/PATH/TO/CASE/ARCHIVE/FOLDER"
atm_domain=""
ocn_domain=""

case_settings=(

    LENS_piControl_oQ_3_f45_g37_SOM_STATIC_20     SOM_STATIC_20     "red"   "-" 
    LENS_piControl_oQ_3_f45_g37_EntOM_STATIC_20   EntOM_STATIC_20   "blue"       "-" 
    LENS_piControl_oQ_3_f45_g37_NKOM_STATIC_20    NKOM_STATIC_20    "green"         "-" 
 
    LENS_piControl_oQ_3_f45_g37_SOM_EKMAN_20      SOM_EKMAN_20      "red"   "--" 
    LENS_piControl_oQ_3_f45_g37_EntOM_EKMAN_20    EntOM_EKMAN_20    "blue"       "--" 
    LENS_piControl_oQ_3_f45_g37_NKOM_EKMAN_20     NKOM_EKMAN_20    "green"         "--" 

    benchmark                                benchmark        "black"    "-."
    
)
