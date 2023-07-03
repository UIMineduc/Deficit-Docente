cd "D:\OneDrive - Ministerio de Educación\2022\18 Deficit Docente\output\v4"
global directorio "D:\OneDrive - Ministerio de Educación\0 0 Bases de datos - MINEDUC\Directorios"

foreach var in Basica Lenguaje Matematicas Ciencias Historia{
	foreach tipo in todos docentes idoneo{
		import excel "tablas_aux_powerbi.xlsx", sheet("`var'_`tipo'") firstrow clear
		
	tempfile `var'_`tipo'
	save "``var'_`tipo''", replace
	}
}

** Enseñanza Básica **
use `Basica_todos', clear
rename def_total2 def_total_Basica
merge 1:1 cod_reg_rbd cod_com_rbd depe using `Basica_docentes',nogen
rename def_total2 def_docentes_Basica
merge 1:1 cod_reg_rbd cod_com_rbd depe using `Basica_idoneo',nogen
rename def_ido2 def_idoneos_Basica

tempfile intermedia_Basica
save "`intermedia_Basica'"


** Enseñanza Media **
foreach var in Lenguaje Matematicas Ciencias Historia{
	display "actualmente mostrando"
use ``var'_todos', clear
rename def_`var'2 def_total_`var'
merge 1:1 cod_reg_rbd cod_com_rbd depe using ``var'_docentes',nogen
rename def_`var'2 def_docentes_`var'
merge 1:1 cod_reg_rbd cod_com_rbd depe using ``var'_idoneo',nogen
rename def_ido_`var'2 def_idoneos_`var'

tempfile intermedia_`var'
save "`intermedia_`var''"
}

use `intermedia_Basica',clear
merge 1:1 cod_reg_rbd cod_com_rbd depe using `intermedia_Lenguaje',nogen
merge 1:1 cod_reg_rbd cod_com_rbd depe using `intermedia_Matematicas',nogen
merge 1:1 cod_reg_rbd cod_com_rbd depe using `intermedia_Ciencias',nogen
merge 1:1 cod_reg_rbd cod_com_rbd depe using `intermedia_Historia',nogen


encode depe, gen(dependencia2)

recode def_*(.=0)

save "230530_powerbi_data.dta"

collapse (sum) def_* , by(dependencia2)
set obs=5

******* Master Data ******
*Directorio

use"230530_powerbi_data.dta", clear

preserve
use "$directorio\directorio_2022.dta",clear
 keep cod_reg_rbd nom_reg_rbd_a cod_com_rbd nom_com_rbd
	duplicates drop cod_reg_rbd nom_reg_rbd_a cod_com_rbd nom_com_rbd, force
	
bys cod_com_rbd: gen id_com=_n

keep if id_com==1

tempfile data_comunas
save `data_comunas'
restore

merge m:1 cod_com_rbd using `data_comunas', keep(3) nogen

order cod_reg_rbd cod_com_rbd nom_reg_rbd_a nom_com_rbd depe dependencia2
drop id_com

*Cambio de Nombre de las regiones*
replace	nom_reg_rbd_a=	"Región de Tarapacá"	if nom_reg_rbd_a==	"TPCA"
replace	nom_reg_rbd_a=	"Región de Antofagasta"	if nom_reg_rbd_a==	"ANTOF"
replace	nom_reg_rbd_a=	"Región de Atacama"	    if nom_reg_rbd_a==	"ATCMA"
replace	nom_reg_rbd_a=	"Región de Coquimbo"	if nom_reg_rbd_a==	"COQ"
replace	nom_reg_rbd_a=	"Región de Valparaíso"	if nom_reg_rbd_a==	"VALPO"
replace	nom_reg_rbd_a=	"Región de O'higgins"	if nom_reg_rbd_a==	"LGBO"
replace	nom_reg_rbd_a=	"Región del Maule"	    if nom_reg_rbd_a==	"MAULE"
replace	nom_reg_rbd_a=	"Región del Bío Bío"	if nom_reg_rbd_a==	"BBIO"
replace	nom_reg_rbd_a=	"Región de La Araucanía"	if nom_reg_rbd_a==	"ARAUC"
replace	nom_reg_rbd_a=	"Región de Los Lagos"	if nom_reg_rbd_a==	"LAGOS"
replace	nom_reg_rbd_a=	"Región de Aysén"	    if nom_reg_rbd_a==	"AYSEN"
replace	nom_reg_rbd_a=	"Región de Magallanes"	if nom_reg_rbd_a==	"MAG"
replace	nom_reg_rbd_a=	"Región Metropolitana"	if nom_reg_rbd_a==	"RM"
replace	nom_reg_rbd_a=	"Región de Los Ríos"	if nom_reg_rbd_a==	"RIOS"
replace	nom_reg_rbd_a=	"Región de Arica y Parinacota"	if nom_reg_rbd_a==	"AYP"
replace	nom_reg_rbd_a=	"Región de Nuble"	    if nom_reg_rbd_a==	"NUBLE"

export excel using "230530_powerbi_data_label.xlsx", replace firstrow(var) cell(B2)

	