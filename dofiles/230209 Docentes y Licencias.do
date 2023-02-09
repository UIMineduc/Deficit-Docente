/*Nota Metodológica
Autor: Alonso Arraño
Fecha: 23-02-09
Respaldo: Los códigos están en la nube del github de la unidad

Función: Caracterización de las licencias médicas en la muestra de docentes que estamos trabajando
*/

clear all

*Directorio AAP
cd "D:\OneDrive - Ministerio de Educación\2022\18 Deficit Docente\Data"

global docentes "D:\OneDrive - Ministerio de Educación\0 0 Bases de datos - MINEDUC\Docentes\Cargos Docentes"
global matricula22 "D:\OneDrive - Ministerio de Educación\0 0 Bases de datos - MINEDUC\Matricula\2022"
global matricula18 "D:\OneDrive - Ministerio de Educación\0 0 Bases de datos - MINEDUC\Matricula\2018"
global directorio "D:\OneDrive - Ministerio de Educación\0 0 Bases de datos - MINEDUC\Directorios"
global output "D:\OneDrive - Ministerio de Educación\2022\18 Deficit Docente\output"


**#Load Data
	
	*import delimited "$docentes\Docentes_2022_publica.csv", varnames(1) encoding(UTF-8) clear 
	*save "$docentes\docentes_2022_publica.dta",replace
	
	use "$docentes\docentes_2022_privada.dta" ,clear
	
	keep if estado_estab==1
	*keep if persona==1
		
	drop estado_estab persona
	keep doc_run rbd id_ifp id_ifs cod_ens_1 cod_ens_2 sector1 sector2 subsector1 subsector2 horas_aula horas1 horas2 tip_tit_id_1 nivel1 nivel2 cod_depe2 cod_reg_rbd cod_com_rbd rural_rbd  esp_id_1 id_itc
	
	
**# Variables y filtros de interés
		* Mantenemos solo RBD urbanos
		keep if rural_rbd==0
		
		* Destring de variables 
		quietly destring, dpcomma replace

	*Mantenemos a quienes ejercen como docente de aula, de forma primaria y a los que hacen clases en basica/media
	*Este se considera el universo de docentes
		keep if inlist(1,id_ifp,id_ifs)
		keep if inlist(110,cod_ens_1,cod_ens_2)
		*keep if inlist(sector1,110,120,130,190) | inlist(sector2,110,120,130,190)
		*keep if inlist(subsector1,11001,11004,12001,12002,13001,13002,13003,13004,19001) | inlist(subsector2,11001,11004,12001,12002,13001,13002,13003,13004,19001)

	codebook doc_run rbd
	*Tenemos un total de 117,075 docentes como universo final de basica usando ifp + ifs
	*considerando un total de 4,873 RBD como universo usando ifp + ifs
	
	****************************************************************************
	*************************** Criterios de Idoneidad *************************
	
	*** Idoneidad Docente
	* Ed basica
	gen ido_bas=0 if inlist(2,nivel1,nivel2) & inlist(subsector1,11001,11004,12001,12002,13001,13002,13003,13004,19001)
	 replace ido_bas=1 if tip_tit_id_1==13 & inlist(2,nivel1,nivel2) & inlist(subsector1,11001,11004,12001,12002,13001,13002,13003,13004,19001)

	 tab ido_bas // proporción de idoneos es el 64%

	**# Agregamos data Licencias
	 bys doc_run: keep if _n==1 // Dejamos sola 1 obs, esto para carectizar la muestra solamente
	 
	 merge 1:m doc_run using "D:\Downloads\Licencias_2022.dta", keepusing(aux n_licencias mean_dias TipodeAusencia TipodeLicenciaMédica dias_lic)
	 drop if _merge==2
	 
	 gen dlic=0 if _merge==1
		replace dlic=1 if _merge==3
		
	drop _merge
	
	frame copy default analisis
	frame change analisis

**# Analisis Licencias

	**# Estadística descriptiva
	
	levelsof TipodeAusencia
	keep if TipodeAusencia=="Licencia Medica" | TipodeAusencia==""
	
	*% con al menos 1 licencia
	bys doc_run: gen id=_n
	tab dlic if id==1

	*cantidad promedio de las licencias
	tabstat n_licencias if id==1 , s(mean sd min max n)
	tabstat dias_lic, s(mean sd min max n)
	twoway kdensity dias_lic
	histogram dias_lic
	
	*TipodeLicenciaMédica
	levelsof TipodeLicenciaMédica
	codebook TipodeLicenciaMédica
	encode TipodeLicenciaMédica, gen(tipo_lic)
	replace tipo_lic=0 if tipo_lic==.
	
	table tipo_lic
	
	*dias totales de licencia
	bys doc_run: egen total_dias=total(dias_lic)
	tabstat total_dias if id==1, s(mean sd min max)
	twoway kdensity total_dias if id==1
	

	 
	 
	**# Analisis posible de cantidad de horas que se podria perder debido a licencias
	********************************************************************************
	* Horas totales del establecimiento*
	*Por subsector1
	preserve
	collapse (sum) horas1, by(rbd sector1 subsector1)
		keep if inlist(subsector1,11001,11004,12001,12002,13001,13002,13003,13004,19001)
	tempfile ofta1
	save `ofta1',replace 
	restore
	
	preserve
	collapse (sum) horas1 if ido_bas==1, by(rbd sector1 subsector1)
		keep if inlist(subsector1,11001,11004,12001,12002,13001,13002,13003,13004,19001)
	rename horas1 hrs_ido1
	tempfile ofta1_ido
	save `ofta1_ido',replace 
	restore
	
	*Por subsector2
	preserve
	collapse (sum) horas2, by(rbd sector2 subsector2)
	rename sector2 sector1
	rename subsector2 subsector1
		keep if inlist(subsector1,11001,11004,12001,12002,13001,13002,13003,13004,19001)
	tempfile ofta2
	save `ofta2',replace 
	restore
	
	preserve
	collapse (sum) horas2 if ido_bas==1, by(rbd sector2 subsector2)
	rename sector2 sector1
	rename subsector2 subsector1
	rename horas2 hrs_ido2
		keep if inlist(subsector1,11001,11004,12001,12002,13001,13002,13003,13004,19001)
	tempfile ofta2_ido
	save `ofta2_ido',replace 
	restore
	
	*agregamos la cantidad de docentes según id_ifp e id_ifs
	*1 - 119,122 docentes ifp
	*2 - 3,640 docentes ifs
	
	bys rbd: egen aux_ifp=count(mrun) if id_ifp==1
	bys rbd: egen ifp=max(aux_ifp)
	bys rbd: egen aux_ifs=count(mrun) if id_ifs==1
	bys rbd: egen ifs=max(aux_ifs)
	drop aux*
	
	bys rbd: keep if _n==1
	keep rbd ifp ifs

	*hasta acá tenemos 4,873 rbd
	
	*Agregamos la información de la cantidad de horas para cada oferta por rbd
	
	merge 1:m rbd using `ofta1'
	drop _merge
	codebook rbd

	merge 1:1 rbd sector1 subsector1 using `ofta1_ido'
	drop _merge
	codebook rbd
	
	merge 1:1 rbd sector1 subsector1 using `ofta2'
	drop _merge
	codebook rbd
	
	merge 1:1 rbd sector1 subsector1 using `ofta2_ido'
	drop _merge
	codebook rbd
********************************************************************************
	* Mantenemos sectores nucleares
	rename sector1 sector
	rename subsector1 subsector
	
	*ajustes del merge
	recode horas1 horas2 hrs_ido1 hrs_ido2(.=0)
	
	bys rbd: egen doc_ifp=max(ifp)
	bys rbd: egen doc_ifs=max(ifs)
	
	drop ifp ifs
	
	*tenemos 7892 rbd con los sectores núcleares en básica. El dato anterior considera otras áreas fuera de NB.
	
	*Horas disponibles del RBD
	*solo horas1
	gen hrs_aula1=horas1
	gen hrs_lect1=hrs_aula1*4*0.65
	
	gen hrs_aula_ido1=hrs_ido1
	gen hrs_lect_ido1=hrs_aula_ido1*4*0.65
	
	*horas1 + horas2
	gen hrs_aula2=horas1+horas2
	gen hrs_lect2=hrs_aula2*4*0.65
	
	gen hrs_aula_ido2=hrs_ido1+hrs_ido2
	gen hrs_lect_ido2=hrs_aula_ido2*4*0.65
	
	collapse (sum) hrs_lect1 hrs_lect_ido1 hrs_lect2 hrs_lect_ido2 (first) doc_ifp doc_ifs, by(rbd)
	
	rename (hrs_lect1 hrs_lect2) (ofta_hrs1 ofta_hrs2)
	rename (hrs_lect_ido1 hrs_lect_ido2) (ofta_hrs_ido1 ofta_hrs_ido2)
	
	
	*Nota: Tenemos 4,881 rbd

	*drop sector subsector horas1 horas2 hrs_*
	
	gen cod_ense2=2

****************************************************************************

