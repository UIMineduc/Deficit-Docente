* Autora: Carla Zúñiga
* Fecha última modificación: 27-02-24
* Código: Se construye base con variable que indica el SLEP asociado a cada rbd

**BASE DE DATOS SLEP POR RBD PARA 2023: DÉFICIT DOCENTE
clear all
set more off


global Sostenedores "D:\OneDrive - Ministerio de Educación\BBDD\Directorio Sostenedores\2023"

*import delimited "$Sostenedores\20230925_Directorio_Oficial_Sostenedores_2023_20230430_PUBL.csv", varnames(1) encoding(UTF-8) clear 
*save "$Sostenedores\sostenedores_2023_publica.dta",replace

use "$Sostenedores\sostenedores_2023_publica.dta", clear
keep rbd_* id_sle nom_sle
keep if id_sle==1
drop id_sle
quietly destring, dpcomma replace

rename rbd_00# rbd_#
rename rbd_0# rbd_#
reshape long rbd_, i(nom_sle) j(id) 
drop if rbd_==.
drop id
rename rbd_ rbd


save "$Sostenedores\rbd_slep_2023.dta",replace
