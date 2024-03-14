* Autora: Carla Zúñiga
* Fecha última modificación: 27-02-24
* Código: Se construye base que presenta indicador de concentración de estudiantes 
* prioritarios superior o igual al 80% por rbd


**# Configuración
clear all
set more off
graph set window fontface "Calibri light" // Dejamos calibri light como formato predeterminado 

**Añadimos fecha para guardar los archivos
global suffix: display %tdCCYY-NN-DD =daily("`c(current_date)'", "DMY")
display "$suffix"

global main "D:\OneDrive - Ministerio de Educación\Proyectos\2024\Déficit docente"
global Data "$main/Data\2023"
global Matricula "D:\OneDrive - Ministerio de Educación\BBDD\Matricula\2023"
global Docentes "D:\OneDrive - Ministerio de Educación\BBDD\Docentes\2023"
global SEP "D:\OneDrive - Ministerio de Educación\BBDD\SEP\2023"
global Output "$main/Output\2023\Nucleares"




**************************** Base de datos - SEP *******************************

*import delimited "$SEP\20231211_Preferentes_Prioritarios_y_Beneficiarios_2023_20231130_WEB.csv", varnames(1) encoding(UTF-8) clear 

**Destring de variables 
*quietly destring, dpcomma replace
*save "$SEP\sep_2023_publica.dta",replace


/// Ya que la base de datos SEP contiene sólo información de estudiantes prioritarios y preferentes,
/// se debe unir a la base de matrícula para tener también la información de los estudiantes que no
/// son ni prioritarios ni preferentes.

use "$Matricula\matricula_unica_2023.dta" ,clear
keep if estado_estab==1
keep mrun rbd rural_rbd cod_ense2
*rename rbd rbd1
save "$Matricula\rbd_mrun_2023.dta",replace


**Se une la base de matrícula con la de estudiantes SEP
use "$SEP\sep_2023_publica.dta" ,clear
keep if estado_estab==1
keep mrun rbd rural_rbd cod_ense2 prioritario_alu

merge 1:1 mrun using "$Matricula\rbd_mrun_2023"
replace prioritario_alu=0 if prioritario_alu==.
drop _merge

bys rbd: egen prioritario=mean(prioritario_alu)
replace prioritario=prioritario*100

**Se mantienen solo RBD urbanos y cod_ense 2, 5 y 7
keep if rural_rbd==0
keep if inlist(cod_ense2,2,5,7)	
bys rbd: keep if _n==1

**
gen vulnerabilidad=0
replace vulnerabilidad=1 if prioritario>=80
tab vulnerabilidad
keep rbd vulnerabilidad
	
save "$SEP\rbd_vulnerabilidad_2023.dta",replace
	
	
	
	
	

