* Autores: Alonso Arraño y Carla Zúñiga
* Fecha última modificación: 02-01-24


* Nota: Este cálculo excluye a los estbalecimientos particulares pagados


**# Configuración
clear all
set more off
graph set window fontface "Calibri light" // Dejamos calibri light como formato predeterminado 

**Añadimos fecha para guardar los archivos
global suffix: display %tdCCYY-NN-DD =daily("`c(current_date)'", "DMY")
display "$suffix"

global main "D:\OneDrive - Ministerio de Educación\Proyectos\Déficit docente"
global Data "$main/Data"
global Plan "$main/Plan de Estudios"
global Matricula "D:\OneDrive - Ministerio de Educación\BBDD\Matricula\2022"
global Docentes "D:\OneDrive - Ministerio de Educación\BBDD\Docentes\2022"
global Directorio "D:\OneDrive - Ministerio de Educación\BBDD\Directorio\2022"
global Sostenedores "D:\OneDrive - Ministerio de Educación\BBDD\Directorio Sostenedores\2022"
global SEP "D:\OneDrive - Ministerio de Educación\BBDD\SEP\2022"
global Output "$main/Output\2022\Nucleares\Basica"



************************** Base de datos - Docentes ****************************

// ESTO ES SOLO SI NO SE TIENE LA BASE EN DTA
*import delimited "$Docentes\20220829_Docentes_2022_20220630_PUBL.csv", varnames(1) encoding(UTF-8) clear 
*save "$Docentes\docentes_2022_publica.dta",replace
*import delimited "$Docentes\20220829_Docentes_2022_20220630_PRIV.csv", varnames(1) encoding(UTF-8) clear 
*save "$Docentes\docentes_2022_privada.dta",replace

	use "$Docentes\docentes_2022_publica.dta" ,clear
	
	**Filtramos EE en funcionamiento
	keep if estado_estab==1
	
	**Dropeamos variables que no se ocupan
	drop estado_estab persona
	
	**Se excluyen a los estbalecimientos particulares pagados
	drop if cod_depe2==3
	
	**Variables de Interés 
	keep mrun rbd id_ifp id_ifs cod_ens_1 cod_ens_2 sector1 sector2 subsector1 subsector2 horas_aula horas1 horas2 tip_tit_id_1 tip_tit_id_2 nivel1 nivel2 cod_depe2 cod_reg_rbd cod_com_rbd rural_rbd esp_id_1 esp_id_2 id_itc tip_insti_id_1 tip_insti_id_2 grado*_1 grado*_2 nom_com_rbd
	order cod_reg_rbd cod_com_rbd cod_depe2 rural_rbd rbd mrun

	**Mantenemos solo RBD urbanos
	keep if rural_rbd==0
		
	**Mantenemos solo docentes titulares y no reemplazantes
	drop if inlist(id_itc,3,7,12,19,20)
		
	**Destring de variables 
	quietly destring, dpcomma replace
		
	**Mantenemos a quienes ejercen como docente de aula, de forma primaria y a los que hacen clases en básica. Este se considera el universo de docentes
	keep if inlist(1,id_ifp,id_ifs)
	keep if inlist(110,cod_ens_1,cod_ens_2)
	keep if inlist(sector1,110,115,120,130,140,150,160,170,180,190,310,320,330,340,350,360,370,380,390,395) | inlist(sector2,110,115,120,130,140,150,160,170,180,190,310,320,330,340,350,360,370,380,390,395)

	*br cod_ens_1 subsector1 sector1 cod_ens_2 subsector2 sector2 horas1 horas2 if !inlist(cod_ens_1,110) 
	*sort subsector1
	
	**Se le asigna missing value a las observaciones que reportan horas para los subsectores incluidos en el análisis, pero que corresponden a otros códigos de enseñanza
	forv i=1/2{
	replace subsector`i'=. if !inlist(cod_ens_`i',110)
	}
	
	tab cod_ens_2 subsector2 if !inlist(cod_ens_2,110)

	codebook mrun rbd
	**Tenemos un total de 98.455 docentes como universo final de basica usando ifp + ifs
	**Con un total de 96.849 únicos
	**Considerando un total de 4,353 RBD como universo usando ifp + ifs
	
**************************** Criterios de Idoneidad ****************************
	
**# Idoneidad Docente

    **Condiciones para considerar:
	**La primera condicion (0) son docentes que hacen clases en el nivel de básica en alguna de estas asignaturas
	**La segunda condicion (1) son docentes que hacen clases y que además tienen la titulación según la ley n°....
	
	**Condicion de titulación
	**Se consideran a los titulados en Básica, Parvularia y Básica, y Básica y Media para básica y sólo título en Media para media
	gen titulo_pedagogia= 1 if (inlist(tip_tit_id_1,13,15,16) | inlist(tip_tit_id_2,13,15,16))
	gen titulo_media=1 if tip_tit_id_1==14|tip_tit_id_2==14
	
	**Condición de hacer clases en 5to a 8vo basico
	forv j=1/2{
	forv i=5/8{
		gen clases_`i'_`j'=1 if cod_ens_`j'==110 & inlist(`i',grado1_`j',grado2_`j',grado3_`j',grado4_`j', grado5_`j', grado6_`j', grado7_`j', grado8_`j', grado9_`j', grado10_`j', grado11_`j', grado12_`j')
	}
	gen d_clases_5_8_`j'=1 if inlist(1,clases_5_`j', clases_6_`j', clases_7_`j', clases_8_`j')
	}
	drop clases_*
	
	**Condición de asignaturas (lenguaje, matemáticas, ciencias, historia & general)
	**Explicación: Genero una variable ido_bas1 o ido_bas2 según el subsector1 o 2 en que hace clases. Luego le asigno el 0 a todos aquellos que declaran hacer clases en alguna de las asignaturas de Ens. Basica explicadas arriba. Asigno 1 a los Idóneos con especialidad, que cumplen la condición de hacer clases en el nivel & tienen la pedagogia en básica
	
	global listado1 inlist(subsector1,11001,11004,12001,12002,13001,13002,13003,13004,19001) 
	global listado2 inlist(subsector2,11001,11004,12001,12002,13001,13002,13003,13004,19001) 
	
	forv i=1/2{
	gen ido_bas`i'= 0 if inlist(subsector`i',11001,11004,12001,12002,13001,13002,13003,13004,19001) 
	replace ido_bas`i'=1 if titulo_pedagogia==1  & inlist(subsector`i',11001,11004,12001,12002,13001,13002,13003,13004,19001)
	replace ido_bas`i'=1 if titulo_media==1 & d_clases_5_8_`i'==1 & inlist(subsector`i',11001,11004,12001,12002,13001,13002,13003,13004,19001) 
	}
	
	**Tasa de especialidad
	**NOTA: en este caso se ignoran los casos en los que un docente hace clases, pero no tiene la especialidad (ido_bas=0) en un subsector, y en el otro sí tiene la especialidad (ido_bas=1) y se considera solamente el mayor (en este caso que sí tiene la especialidad). Esto es posible que genere una tasa de especialidad subestimada, dado que no estoy incorporando en el universo a estos docentes que hacen clases en un subsector en el cual no tienen la especialidad.
	
	**Variable que agrupa subsector1 y subsector2 y asigna el mayor valor, en este caso sí se tiene la especialidad
	egen tasa_especialidad=rowmax(ido_bas1 ido_bas2)
	
	tab ido_bas1 // proporción de Idóneos es el 77,31%
	tab ido_bas2 // proporción de Idóneos es el 79,20%
	tab tasa_especialidad // proporción de Idóneos con especialidades el 77,83%
	tabstat tasa_especialidad , by(cod_reg_rbd) save f( %9.4f)
	 
	 
**# Estadistica descriptiva

	**Cantidad de docentes que ejercen en las asignaturas filtradas, ya sean habilitados o con la especialidad (0 o 1)
	codebook mrun if tasa_especialidad!=. //71.043

	**Distribución de los docentes por dependencia y región
	tab cod_depe2 if tasa_especialidad!=.
	tab cod_reg_rbd if tasa_especialidad!=.
	 
	**Para capturar la cantidad de establecimientos participantes debemos generar una aux a nivel de rbd que capture si tiene docentes en alguna de estas áreas
	bys rbd: egen aux_contador_rbd=max(tasa_especialidad)
	codebook rbd if aux_contador_rbd!=.	 
	 
	**Tasa de docentes generalistas
	gen doc_generalista=0 
	replace doc_generalista=1 if inlist(19001,subsector1,subsector2)
	tab doc_generalista
	 	
	
******************************* Oferta de horas ********************************

	
**# Oferta de horas por RBD y Asignatura
    **Horas totales del establecimiento por cada subsector1 o subsector2
	**Subsector1
	**Oferta de horas idóneas
	preserve
	keep if inlist(subsector1,11001,11004,12001,12002,13001,13002,13003,13004,19001)
	collapse (sum) horas1 , by(rbd subsector1)	
	tempfile ofta1
	save `ofta1',replace 
	restore
	
	**Oferta de horas idóneas especialistas
	preserve
	keep if inlist(subsector1,11001,11004,12001,12002,13001,13002,13003,13004,19001)
	collapse (sum) horas1 if ido_bas1==1, by(rbd subsector1)
	rename horas1 hrs_ido1
	tempfile ofta1_ido
	save `ofta1_ido',replace 
	restore

	
	**Subsector2
	**Oferta de horas idóneas
	preserve
	keep if inlist(subsector2,11001,11004,12001,12002,13001,13002,13003,13004,19001)
	collapse (sum) horas2, by(rbd subsector2)
	rename subsector2 subsector1
	tempfile ofta2
	save `ofta2',replace 
	restore
	
	**Oferta de horas idóneas especialistas
	preserve
	keep if inlist(subsector2,11001,11004,12001,12002,13001,13002,13003,13004,19001)
	collapse (sum) horas2 if ido_bas2==1, by(rbd subsector2)
	rename subsector2 subsector1
	rename horas2 hrs_ido2
	tempfile ofta2_ido
	save `ofta2_ido',replace 
	restore
	
	**Agregamos la cantidad de docentes según id_ifp e id_ifs
	codebook mrun if id_ifp==1
    codebook mrun if id_ifs==1
	*1 - 96.805 docentes ifp
	*2 - 1.650 docentes ifs
	
	**Cantidad de docentes por establecimiento 
	bys rbd: egen aux_ifp=count(mrun) if id_ifp==1
	bys rbd: egen ifp=max(aux_ifp)
	bys rbd: egen aux_ifs=count(mrun) if id_ifs==1
	bys rbd: egen ifs=max(aux_ifs)
	drop aux*
	
	**Se deja solamente una observación por rbd
	bys rbd: keep if _n==1
	keep rbd ifp ifs

	**Hasta acá tenemos 4,353 rbd
	
	**Agregamos la información de la cantidad de horas para cada oferta por rbd
	use `ofta1',clear
	append using `ofta1_ido'
	append using `ofta2'
	append using `ofta2_ido'
	
	tempvar tot1_h1
	egen `tot1_h1'=total(horas1)
	
	display "horas 1 totales:"
	levelsof `tot1_h1'
		
	**Mantenemos sectores nucleares
	rename subsector1 subsector
	
	**Ajustes del append
	recode horas1 horas2 hrs_ido1 hrs_ido2 (.=0)
	
	codebook rbd // El codebook arroja 4.344 establecimientos
	
**# Horas totales y Horas Lectivas
	**Horas disponibles del RBD
	
	//// SUPUESTO: las horas aula consideran lectivas + no lectivas, por lo que
	//// se utiliza el 65% de ellas como horas lectivas cronológicas mensuales

	**Total de horas aula mensuales
	gen hrs_aula2=horas1+horas2
	gen hrs_lect2=hrs_aula2*4*0.65 

	gen hrs_aula_ido2=hrs_ido1+hrs_ido2
	gen hrs_lect_ido2=hrs_aula_ido2*4*0.65 

	
	collapse (sum) hrs_lect2 hrs_lect_ido2, by(rbd)
	rename (hrs_lect2 hrs_lect_ido2) (ofta_hrs2 ofta_hrs_ido2)
	
	**El sufijo 2 hace referencia al total de horas
	**El codebook arroja 4.325 establecimientos
	**Se agrega cod_ense de Nivel basica para hacer el match con la demanda de horas
	gen cod_ense2=2

***************************** Oferta y Demanda EE ******************************


**# Merge Oferta y Demanda de EE

	preserve
	use "$Data\dda_hrs_rbd_nivel_2022_38sem_v1.dta",clear
	keep if cod_ense2==2
	keep if rural_rbd==0
	tempfile dda
	save `dda'
	restore

	merge 1:1 rbd cod_ense2 using `dda', keepusing(n_cursos dda_hrs_basica)
	rename _merge merge_dda
	**drop if _merge==1 //24 RBD con docentes pero sin matricula en el nivel. 
	**drop if _merge==2 //26 RBD con cursos pero sin docentes principales
	**Lo anterior es anómalo, y es una de las limitaciones del modelo que existan establecimientos con discrepancias entre las clases y docentes
	
	**Agregamos data administrativa
	merge 1:1 rbd using "$Directorio\directorio_2022",  keepusing(cod_reg_rbd cod_com_rbd cod_depe2 nom_com_rbd) keep(3)
	drop _merge
	
	tab merge_dda cod_depe2
	drop if merge_dda!=3
	drop merge_dda
	
	**Actualización nos quedamos con 4320 debido a la nueva condición de docentes Idóneos
	
	
****************************** Cálculo del déficit *****************************	
	
**# Transformación de horas a Docentes
	
	/// Nota: El déficit se entiende como la diferencia entre horas disponibles y
	/// horas demandadas
	
	* La transformacion de horas a n de docentes se basa en la mediana/promedio
	* de horas aula totales de los docentes, lo que se presenta en las figuras de
	* caracterizacion de horas aula de la sección superior. Dado que un docente 
	* hace 30 horas semanales y el 65% de estas son lectivas, se divide por la  
	* multiplicación (28*0,65)
	
    **Cálculo del déficit idóneo
	gen def_total2=ofta_hrs2-dda_hrs_basica
	replace def_total2=def_total2/(28*0.65)
	
	**Cálculo del déficit idóneo especialista
	gen def_ido2=ofta_hrs_ido2-dda_hrs_basica
	replace def_ido2=def_ido2/(28*0.65) 
	
	**Cálculo de la demanda de horas transformado en docentes
	replace dda_hrs_basica=dda_hrs_basica/(28*0.65)
	

	

**# Establecimientos en situación de déficit

	* Esta es una de las innovaciones que hicimos para el cálculo del déficit
	* a nivel de establecimientos a diferencia de elige educar. Esta diferencia
	* implica que tenemos SIEMPRE un n mas alto de déficit
	
	**Establecimientos con déficit idóneo
	gen d_def_tot2=1 if def_total2<0
	replace d_def_tot2=0 if def_total2>=0
	
	**Establecimientos con déficit idóneo especialista
	gen d_def_ido2=1 if def_ido2<0
	replace d_def_ido2=0 if def_ido2>=0
	

**# Redondeo del déficit según situación


	/// Redondeamos debido a que no podemos tener de déficit 1,5 profes para un establecimiento
	
	**Idóneo
	replace def_total2=ceil(def_total2) if d_def_tot2==0
	replace def_total2=floor(def_total2) if d_def_tot2==1
	
	**Idóneo especialista
	replace def_ido2=ceil(def_ido2) if d_def_ido2==0
	replace def_ido2=floor(def_ido2) if d_def_ido2==1

	
	
**# Gráficos - Horas totales - DENSIDAD
	
	twoway kdensity def_total2  , lp(solid) lcolor("15 105 180"*0.8) lw(medthick)  || ///
	kdensity def_ido2 , lp(dash) lw(medthick) lcolor("235 60 70"*0.8) ///
	title("Densidad dif. estimada de docentes en Ens. Básica",color(black) margin(medium) ) ///
	legend(label(1 "Idóneos") label(2 "Con especialidad") region(fcolor(none) lcolor(none))) ///
	xtitle("Diferencia docentes estimada") ytitle("Densidad") ///
	graphregion(c(white)) xlabel(#10) ///
	xline(0,lcolor("235 60 70"*0.8))  
	graph export "$Output\240103_def_basica_2022_38sem.png",replace

**# Gráficos - Horas totales - BOXPLOT
	graph box def_total2, ///
	legend(label(1 "Idóneos") label(2 "Con especialidad")) ///
	graphregion(c(white)) ///
	box(1, color("15 105 180"*0.8)) ///
	box(2, color("235 60 70"*0.8)) ///
	nooutsides ytitle("Diferencia") ///
	legend(region(fcolor(none) lcolor(none))) ///
	note("Nota: Se excluyen los valores externos") ///
	yline(0, lpattern(solid) lcolor(black*0.6))	
	graph export "$Output\240103_boxplot_def_basica_2022_38sem.png",replace
	graph export "$Output\240103_boxplot_def_basica_2022_38sem.svg",replace
	
	
	*Sacamos esto por politica CEM
	*title("Distribución dif. estimada de docentes Educación Básica",color(black) margin(medium)) ///
	
	save "$Data\240103_ofta_dda_basica_2022_v1.dta",replace

	
****************************** Resultados finales ******************************	

	use "$Data\240103_ofta_dda_basica_2022_v1",clear
	
	
**# Se generan tramos de docentes faltantes para calcular el % de establecimientos con déficit por tramos
	tab def_total2 if d_def_tot2==1
	summarize def_total2 if d_def_tot2==1,d 
	gsort -def_total2
	
	
	**Distribución de establecimientos con déficit docente
	preserve
	keep if d_def_tot2==1
	gsort -def_total2
	replace def_total2=def_total2*-1 if d_def_tot2==1
	summarize def_total2 if d_def_tot2==1,d 


	local p25= `r(p25)'
	local p50= `r(p50)'
	local p75= `r(p75)'
	
	histogram def_total2 if d_def_tot2==1, width(1) discrete ///
	xline(`p25',lcolor("235 60 70"*0.8))  ///
	xline(`p50',lcolor("235 60 70"*0.8))  ///
	xline(`p75',lcolor("235 60 70"*0.8))  ///	
	color( "0 112 150") ///
	lcolor( "0 112 150") ///
	lwidth(thin) ///
	fin(inten60) ///
	graphregion(c(white)) ///
	xtitle("Cantidad de docentes faltantes ",margin(small)) ///
	ytitle("Densidad") ///
	xlabel(1 5 10 15 20 25 30 35 40 44)
	graph export "$Output\distribucion_docentes_faltantes_basica.png" , replace
    restore
	
	**Variable dicotómica para cada tramo
	gen tramo1=0
	replace tramo1=1 if def_total2 >-3 & d_def_tot2==1
	
	gen tramo2=0
	replace tramo2=1 if def_total2 <=-3 & def_total2 >-6 & d_def_tot2==1
	
	gen tramo3=0
	replace tramo3=1 if def_total2 <=-6 & d_def_tot2==1
	

	**Porcentaje de EE con déficit por tramos	
	tabstat tramo1 tramo2 tramo3, s(mean) f(%9.4f)

	preserve
	collapse (mean) tramo1 tramo2 tramo3
	export excel using "$Output\240103_porcent_def_basica_tramo_2022_v1.xlsx", sheet(EE_def_tramo,modify) firstrow(var) cell(B2)
	restore



**# Porcentaje de EE con déficit por región	
	*tabstat d_def_tot1 d_def_ido1 d_def_tot2 d_def_ido2, by(cod_reg_rbd)
	tabstat d_def_tot2 d_def_ido2, by(cod_reg_rbd) s(mean) f(%9.4f)
	tab cod_reg_rbd d_def_tot2
	tab cod_reg_rbd d_def_ido2
	
	
	local x=2
	local letter: word `x' of `c(ALPHA)'
	display "`letter'"
	preserve
	collapse (mean) d_def_tot2 d_def_ido2 , by(cod_reg_rbd)
	export excel using "$Output\240103_porcent_def_basica_reg_2022_v1.xlsx", sheet(EE_def_region,modify) firstrow(var) cell("`letter'2")
	restore
	local x=`x'+5
	
**# Total de docentes que faltan por región
	tabstat def_total2 if d_def_tot2==1 , by(cod_reg_rbd) s(sum)
	tabstat def_ido2 if d_def_ido2==1 , by(cod_reg_rbd) s(sum)
	
	preserve	
	collapse (sum) def_total2 if d_def_tot2==1 , by(cod_reg_rbd)
	export excel using "$Output\240103_def_basica_reg_2022_v1.xlsx", sheet(reg_basica,modify) firstrow(var) cell(B2)
	restore 

	preserve	
	collapse (sum) def_ido2 if d_def_ido2==1 , by(cod_reg_rbd)
	export excel using "$Output\240103_def_basica_reg_2022_v1.xlsx", sheet(reg_basica,modify) firstrow(var) cell(G2)
	restore 
	
	preserve	
	collapse (sum) dda_hrs_basica, by(cod_reg_rbd)
	export excel using "$Output\240103_def_basica_reg_2022_v1.xlsx", sheet(reg_basica,modify) firstrow(var) cell(K2)
	restore 	
	

**# Total de docentes que faltan por dependencia y asignatura
	
	**Definición de Dependencia
	gen depe=.
	replace depe=1 if cod_depe2==1
	replace depe=2 if inlist(cod_depe2,2,4)
	replace depe=3 if cod_depe2==5
	label define depe 1 "Municipal" 2 "Subvencionado" 3 "SLEP"
	label values depe depe
	
	preserve	
	collapse (sum) def_total2 if d_def_tot2==1 , by(depe)
	sort depe
	export excel using "$Output\240103_def_basica_depe_2022_v1.xlsx", sheet(depe_basica,modify) firstrow(var) cell(B2)
	restore 

	preserve	
	collapse (sum) def_ido2 if d_def_ido2==1 , by(depe)
	sort depe
	export excel using "$Output\240103_def_basica_depe_2022_v1.xlsx", sheet(depe_basica,modify) firstrow(var) cell(F2)
	restore 

	preserve	
	collapse (sum) dda_hrs_basica , by(depe)
	sort depe
	export excel using "$Output\240103_def_basica_depe_2022_v1.xlsx", sheet(depe_basica,modify) firstrow(var) cell(K2)
	restore 	
	
**# Porcentaje de EE con déficit por dependencia	
	tabstat d_def_tot2 d_def_ido2, by(depe) s(mean) f(%9.4f)
	tab depe d_def_tot2
	tab depe d_def_ido2	

	local x=2
	local letter: word `x' of `c(ALPHA)'
	display "`letter'"
	preserve
	collapse (mean) d_def_tot2 d_def_ido2 , by(depe)
	export excel using "$Output\240103_porcent_def_basica_depe_2022_v1.xlsx", sheet(EE_def_depe,modify) firstrow(var) cell("`letter'2")
	restore
	local x=`x'+5	
	
	
**# Porcentaje de EE con déficit por SLEP	
	merge 1:1 rbd using "$Sostenedores\rbd_slep_2022.dta"
	drop if _merge==2
	drop _merge
	
	
	**Variable dicotómica para cada SLEP
	gen andalien_sur=0 if depe==3
	replace andalien_sur=1 if nom_sle=="ANDALIÉN SUR" & d_def_tot2==1
	
	gen atacama=0 if depe==3
	replace atacama=1 if nom_sle=="ATACAMA" & d_def_tot2==1

	gen barrancas=0 if depe==3
	replace barrancas=1 if nom_sle=="BARRANCAS" & d_def_tot2==1

	gen chinchorro=0 if depe==3
	replace chinchorro=1 if nom_sle=="CHINCHORRO" & d_def_tot2==1

	gen colchagua=0 if depe==3
	replace colchagua=1 if nom_sle=="COLCHAGUA" & d_def_tot2==1

	gen costa_araucania=0 if depe==3
	replace costa_araucania=1 if nom_sle=="COSTA ARAUCANÍA" & d_def_tot2==1

	gen gab_mistral=0 if depe==3
	replace gab_mistral=1 if nom_sle=="GABRIELA MISTRAL" & d_def_tot2==1

	gen huasco=0 if depe==3
	replace huasco=1 if nom_sle=="HUASCO" & d_def_tot2==1

	gen llanquihue=0 if depe==3
	replace llanquihue=1 if nom_sle=="LLANQUIHUE" & d_def_tot2==1

	gen pto_cordillera=0 if depe==3
	replace pto_cordillera=1 if nom_sle=="PUERTO CORDILLER" & d_def_tot2==1
	
	gen valparaiso=0 if depe==3
	replace valparaiso=1 if nom_sle=="VALPARAÍSO" & d_def_tot2==1
	
	
	tabstat andalien_sur atacama barrancas chinchorro colchagua costa_araucania gab_mistral huasco llanquihue pto_cordillera valparaiso, s(mean) f(%9.4f)
	
	preserve
	collapse (mean) andalien_sur atacama barrancas chinchorro colchagua costa_araucania gab_mistral huasco llanquihue pto_cordillera valparaiso
	export excel using "$Output\240103_porcent_def_basica_depe_2022_v1.xlsx", sheet(EE_def_slep,modify) firstrow(var) cell(B2)
	restore

	**Se agrega información sobre la concentración de alumnos prioritarios por rbd para la distribución de horas lectivas y no lectivas
	merge 1:1 rbd using "$SEP\rbd_vulnerabilidad_2022"
	drop if _merge!=3
	drop _merge	

	
	
	
	
		
	
	
	
	