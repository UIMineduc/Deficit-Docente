*Autor: Alonso Arraño
*Fecha ultima modificacion: 29-05-23
*Nota: Este es quizás el proyecto más importante que hice en el CEM, tratenlo con cariño
* Hay un montón de horas y reuniones detrás de este cálculo.


*** Listado de RBD que no reportan docentes en enseñanza básica

clear all
*Directorio AAP

cd "D:\OneDrive - Ministerio de Educación\2022\18 Deficit Docente\Data"

global docentes "D:\OneDrive - Ministerio de Educación\0 0 Bases de datos - MINEDUC\Docentes\Cargos Docentes"
global matricula22 "D:\OneDrive - Ministerio de Educación\0 0 Bases de datos - MINEDUC\Matricula\2022"
global directorio "D:\OneDrive - Ministerio de Educación\0 0 Bases de datos - MINEDUC\Directorios"
global output "D:\OneDrive - Ministerio de Educación\2022\18 Deficit Docente\output\v3"



*3- Determinar cuántos docentes titulados por materia seleccionada ejercen como función principal la docencia de aula en cada rbd.

**#Load Data
	
	*import delimited "$docentes\Docentes_2022_PUBLICA.csv", varnames(1) encoding(UTF-8) clear 
	*save "$docentes\docentes_2022_publica.dta",replace
	
	use "$docentes\docentes_2022_publica.dta" ,clear
	
	keep if estado_estab==1
	
	drop estado_estab persona
	
	*Variables de Interés 
	keep mrun rbd id_ifp id_ifs cod_ens_1 cod_ens_2 sector1 sector2 subsector1 subsector2 horas_aula horas1 horas2 tip_tit_id_1 tip_tit_id_2 nivel1 nivel2 cod_depe2 cod_reg_rbd cod_com_rbd rural_rbd esp_id_1 esp_id_2 id_itc tip_insti_id_1 tip_insti_id_2
	
	order cod_reg_rbd cod_com_rbd cod_depe2 rural_rbd rbd mrun
	
**# Análisis
		* Mantenemos solo RBD urbanos
		keep if rural_rbd==0
		
		* Mantenemos solo docentes titulares y no reemplazantes
		drop if inlist(id_itc,3,7,12,19,20)
		
		* Destring de variables 
		quietly destring, dpcomma replace
		
	*Mantenemos a quienes ejercen como docente de aula, de forma primaria y a los que hacen clases en basica/media
	*Este se considera el universo de docentes
		keep if inlist(1,id_ifp,id_ifs)
		keep if inlist(110,cod_ens_1,cod_ens_2)


	codebook mrun rbd
	*Tenemos un total de 114.483 docentes como universo final de basica usando ifp + ifs
	* Con un total de 112.225 únicos
	*considerando un total de 4,873 RBD como universo usando ifp + ifs
	
	****************************************************************************
	*************************** Criterios de Idoneidad *************************
	
**# Idoneidad Docente
	* Ed basica
	*gen ido_bas=0 if inlist(2,nivel1,nivel2) & inlist(subsector1,11001,11004,12001,12002,13001,13002,13003,13004,19001)
	*replace ido_bas=1 if inlist(13,tip_tit_id_1,tip_tit_id_2) & inlist(2,nivel1,nivel2) & inlist(subsector1,11001,11004,12001,12002,13001,13002,13003,13004,19001)
	 
	*Versión 2
	**# Ed Básica
	*La primera condicion (0) son docentes que hacen clases en el nivel de básica en alguna de estas asignaturas
	*La segunda condicion (1) son docentes que hacen clases y que además tienen la titulación según la ley n°....
	
	* condicion de titulacion
	gen titulo_pedagogia= 1 if (inlist(tip_tit_id_1,13,15,16) | inlist(tip_tit_id_2,13,15,16))
	
	
	* condicion de asignaturas (lenguaje, matemáticas, ciencias, historia & general)
	gen ido_bas1= 0 if inlist(subsector1,11001,11004,12001,12002,13001,13002,13003,13004,19001) 
		replace ido_bas1=1 if titulo_pedagogia==1  & inlist(subsector1,11001,11004,12001,12002,13001,13002,13003,13004,19001)
		
	gen ido_bas2=0 if inlist(subsector2,11001,11004,12001,12002,13001,13002,13003,13004,19001)
		replace ido_bas2=1 if titulo_pedagogia==1 & inlist(subsector2,11001,11004,12001,12002,13001,13002,13003,13004,19001)
		
	gen tasa_idoneidad=1 if inlist(1,ido_bas1,ido_bas2)
		replace tasa_idoneidad=0 if (ido_bas1==0 & ido_bas2==0) | (ido_bas1==0 & ido_bas2==.) | (ido_bas1==. & ido_bas2==0)
	
	**# Tasa de Idoneidad
	** Descrición por sector **
	 *tab ido_bas // proporción de idoneos es el 64%
	 tab ido_bas1 // proporción de idoneos es el 69%
	 tab ido_bas2 // proporción de idoneos es el 34%
	 tab tasa_idoneidad // proporción de idoneos es el 63,65%
	 tabstat tasa_idoneidad , by(cod_reg_rbd) save f( %9.2f)
	 
**# Estadística descriptiva Cargo Docente
	*tasa de idoneidad docente en básica
	tabstat tasa_idoneidad, by(cod_depe2)
	
	*Distribución horas_aula 
	*opcion 1*
	summarize horas_aula,d 
	local mediana= `r(p50)'
	
	kdensity horas_aula, lcolor("15 105 180"*0.8) ///
	xline(`mediana',lcolor("235 60 70"*0.8))  ///
	graphregion(c(white)) ///
	title("Distribución horas de aula, Ed. básica",color(black) margin(medium)) ///
	xtitle("Horas de aula") ///
	ytitle("Densidad") ///
	note("Notas:Horas cronológicas")
	
	*opcion 2
	summarize horas_aula,d 
	local mediana= `r(p50)'
	
	histogram horas_aula, width(1) discrete ///
	xline(`mediana',lcolor("235 60 70"*0.8))  ///
	color( midblue%60) ///
	graphregion(c(white)) ///
	title("Distribución horas de aula, Ed. básica",color(black) margin(medium)) ///
	xtitle("Horas de aula") ///
	ytitle("Densidad") ///
	xlabel(0 5 10 15 20 25 30 35 40 44) ///
	note("Notas:Horas cronológicas")
	
	**# Caracterizacion Docentes Basica
	
	graph box horas_aula, nooutsides
	
	gen aux=horas1+horas2
	summarize aux,d
	
	table id_itc cod_depe2
	
	** Tablas
	tab cod_depe2
	tab sector1
	tab id_ifs

	********************************************************************************
**# Oferta de horas por RBD y Asignatura
	* Horas totales del establecimiento*
	*Por subsector1
	preserve
	collapse (sum) horas1 , by(rbd sector1 subsector1)
		keep if inlist(subsector1,11001,11004,12001,12002,13001,13002,13003,13004,19001)
	tempfile ofta1
	save `ofta1',replace 
	restore
	
	preserve
	collapse (sum) horas1 if ido_bas1==1, by(rbd sector1 subsector1)
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
	collapse (sum) horas2 if ido_bas2==1, by(rbd sector2 subsector2)
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
	recode horas1 horas2 hrs_ido1 hrs_ido2 (.=0)
	
	bys rbd: egen doc_ifp=max(ifp)
	bys rbd: egen doc_ifs=max(ifs)
	
	drop ifp ifs
	
	order doc_ifp doc_ifs, a(rbd)
	

	*el codebook arroja 4.873 establecimientos
	
**# Horas totales y Horas Lectivas
	*Horas disponibles del RBD
	
	*Acá tenemos el total de horas aula 
	gen hrs_aula2=horas1+horas2
	gen hrs_lect2=hrs_aula2*4*0.65
	
	gen hrs_aula_ido2=hrs_ido1+hrs_ido2
	gen hrs_lect_ido2=hrs_aula_ido2*4*0.65
	
	collapse (sum)   hrs_lect2 hrs_lect_ido2 (first) doc_ifp doc_ifs , by(rbd)
	
	rename ( hrs_lect2 hrs_lect_ido2) ( ofta_hrs2 ofta_hrs_ido2)
	
	*El sufijo 2 hace referencia al total de horas
	
	*Nota: Tenemos 4,881 rbd
	*Nota: Tenemos 4,873 rbd en la revision pq borramos reemplazos
	
	gen cod_ense2=2

****************************************************************************


**# Merge Oferta y Demanda de EE

	preserve
	use "dda_hrs_rbd_nivel_2022_38sem.dta",clear
	keep if cod_ense2==2
	keep if rural_rbd==0
	tempfile dda
	save `dda'
	restore

	merge 1:1 rbd cod_ense2 using `dda', keepusing(n_cursos dda_hrs_basica)
	rename _merge merge_dda
	*drop if _merge==1 //53 RBD con docentes pero sin matricula en el nivel. 
	*drop if _merge==2 //21 RBD con cursos pero sin docentes principales
	
	*agregamos data administrativa
	merge 1:1 rbd using "$directorio\directorio_2022",  keepusing(cod_reg_rbd cod_com_rbd cod_depe2) keep(3)
	drop _merge
	
	tab merge_dda cod_depe2
	drop if merge_dda!=3
	drop merge_dda
	
	*Nos quedamos con 4.820 EE completos

**# Cálculo del Deficit
	**# De horas a Docentes
		
	*1 + 2
	gen def_total2=ofta_hrs2-dda_hrs_basica
	replace def_total2=def_total2/(30*0.65)
	
	gen def_ido2=ofta_hrs_ido2-dda_hrs_basica
		replace def_ido2=def_ido2/(30*0.65)
		
	**# establecimiento en situacion de deficit
	*horas 1+2
	gen d_def_tot2=1 if def_total2<0
		replace d_def_tot2=0 if def_total2>=0
	
	gen d_def_ido2=1 if def_ido2<0
		replace d_def_ido2=0 if def_ido2>=0
	
	* Redondeo del deficit segun situacion
	
	replace def_total2=ceil(def_total2) if d_def_tot2==0
	replace def_total2=floor(def_total2) if d_def_tot2==1
	
	replace def_ido2=ceil(def_ido2) if d_def_ido2==0
	replace def_ido2=floor(def_ido2) if d_def_ido2==1


	save "230519_ofta_dda_basica_2022_38sem.dta",replace

	*save "ofta_dda_basica_2022",replace
	tempfile simulacion
	save `simulacion'
	
	
**# Base Final

	*use "ofta_dda_basica_2022",clear
	use `simulacion',clear
	
	**# Graficos Horas1 y Horas totales
	**********
	** NOTA: LA MAYORIA DE LAS HORAS SE ENCUENTRAN EN HORAS 1
	
	
	/* Gráficos considerando horas1 y horas 1+2
	
	twoway kdensity def_total1 || kdensity def_total2 || kdensity def_ido1 || kdensity def_ido2, title("Densidad del déficit docente") legend(label(1 "Deficit Total 1") label(2 "Deficit Total 1+2") label(3 "Deficit Idoneo 1") label(4 "Deficit Idoneo 1 +2"))
	graph export "$output\221129_distr_def_basica_2022.png",replace
	
	graph box def_total1  def_total2   def_ido1   def_ido2,title("Distribución del déficit docente") legend(label(1 "Deficit Total 1") label(2 "Deficit Total 1+2") label(3 "Deficit Idoneo 1") label(4 "Deficit Idoneo 1 +2"))
	graph export "$output\221129_boxplot_def_basica_2022.png",replace
	*/
	
	**# Graficos - Horas totales - DENSIDAD
	
	twoway kdensity def_total2  , lp(solid) lcolor("15 105 180"*0.8) lw(medthick)  || ///
	kdensity def_ido2 , lp(dash) lw(medthick) lcolor("235 60 70"*0.8) ///
	title("Densidad dif. estimada de docentes en Ens. Básica",color(black) margin(medium) ) ///
	legend(label(1 "Docentes Totales") label(2 "Docentes Idóneos") region(fcolor(none) lcolor(none))) ///
	xtitle("Diferencia docentes estimada") ytitle("Densidad") ///
	graphregion(c(white))
	
	graph export "$output\230519_def_basica_2022_38sem.png",replace

	**# Graficos - Horas totales - BOXPLOT
	graph box def_total2 def_ido2, ///
	title("Distribución dif. estimada de docentes Educación Básica",color(black) margin(medium)) ///
	legend(label(1 "Docentes Totales") label(2 "Docentes Idóneos")) ///
	graphregion(c(white)) ///
	box(1, color("15 105 180"*0.8)) ///
	box(2, color("235 60 70"*0.8)) ///
	nooutsides ytitle("Diferencia") ///
	legend(region(fcolor(none) lcolor(none))) ///
	note("Nota: Se excluyen los valores externos") ///
	yline(0, lpattern(solid) lcolor(black*0.6))
	
	graph export "$output\230519_boxplot_def_basica_2022_38sem.png",replace
	

	
**# Tablas finales
	*Indicador por region y comuna
	bys cod_com_rbd: gen id_com=_n==1
	bys cod_reg_rbd: gen id_reg=_n==1
	
		
		*% de EE con déficit por región
		
	*tabstat d_def_tot1 d_def_ido1 d_def_tot2 d_def_ido2, by(cod_reg_rbd)
	tabstat d_def_tot2 d_def_ido2, by(cod_reg_rbd) s(mean) f(%9.4f)


	**# Total de docentes que faltan por comuna

/* DESCRIPCION TABLAS

Basica_neto: Se debe obtener el total de cada fila, estos valores corresponden al supuesto de Considerando reasignación docente dentro de la región	

Basica_como basica: Se debe considerar la suma de todos los valores dentro de la región, dado que existe Sin considerar reasignación dentro de la región	


Basica_neto_com: Se debe generar una dummy si el valor es negativo o no, asi luego se sumaran todos los valores negativos para cada región, Considerando reasignación docente dentro de la comuna de la región	


*/
	
	*1-NO NETEO! Comunal
	preserve	
	collapse (sum) def_total2 (first) cod_reg_rbd if d_def_tot2==1 , by(cod_com_rbd)
				export excel using "$output\230519_n_def_doc_38sem_2022_v2", sheet(basica_com,modify) firstrow(var) cell(B2)
	restore 

	preserve	
	collapse (sum) def_ido2 (first) cod_reg_rbd if d_def_ido2==1 , by(cod_com_rbd)
				export excel using "$output\230519_n_def_doc_38sem_2022_v2", sheet(basica_com,modify) firstrow(var) cell(F2)
	restore 

**# Analisis por Dependencia
	
	*Definición de Dependencia
	*generamos la dependencia para el CEM entre público y part.sub
	gen depe=.
		replace depe=1 if cod_depe2==1
		replace depe=2 if inlist(cod_depe2,2,4)
		replace depe=3 if cod_depe2==3
		replace depe=4 if cod_depe2==5
		
	label define depe 1 "Público" 2 "Subvencionado" 3 "Particular" 4 "SLEP"
	label  values depe depe
	
	
	**# Tablas
	*NO NETEO! Comunal
	preserve	
	collapse (sum) def_total2 (first) cod_reg_rbd if d_def_tot2==1 , by(cod_com_rbd depe)
	sort depe cod_com_rbd
	export excel using "$output\230519_n_def_doc_38sem_2022_v2", sheet(depe_basica,modify) firstrow(var) cell(B2)
	restore 

	preserve	
	collapse (sum) def_ido2 (first) cod_reg_rbd if d_def_ido2==1 , by(cod_com_rbd depe)
	sort depe cod_com_rbd
	export excel using "$output\230519_n_def_doc_38sem_2022_v2", sheet(depe_basica,modify) firstrow(var) cell(F2)
	restore 
	


