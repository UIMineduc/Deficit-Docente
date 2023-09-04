*Autor: Alonso Arraño
*Fecha ultima modificacion: 20-07-23
*Se añaden comentarios a cada seccion para hacer mas facil el traspaso de informacion a Mario o la persona nueva.

*Nota: Este es quizás el proyecto más importante que hice en el CEM, tratenlo con cariño
*Hay un montón de horas y reuniones detrás de este cálculo.

**# Configuracion
clear all
graph set window fontface "Calibri light" // Dejamos calibri light como formato predeterminado 

*Directorio AAP
*Proyecto
cd "D:\OneDrive - Ministerio de Educación\2022\18 Deficit Docente\Data"

/* Estructura proyecto

-0 0 Bases MINEDUC
	- Docentes 
		- 2022
	- Matriculas
		- 2022
	- Directorio
		- 2022
*/

*Carpetas con las bbdd
global docentes "D:\OneDrive - Ministerio de Educación\0 0 Bases de datos - MINEDUC\Docentes\Cargos Docentes"
global matricula22 "D:\OneDrive - Ministerio de Educación\0 0 Bases de datos - MINEDUC\Matricula\2022"
global directorio "D:\OneDrive - Ministerio de Educación\0 0 Bases de datos - MINEDUC\Directorios"
global output "D:\OneDrive - Ministerio de Educación\2022\18 Deficit Docente\output\v5"


**#Load Data - Docentes
	
	// ESTO ES SOLO SI NO SE TIENE LA BASE EN DTA
	*import delimited "$docentes\Docentes_2022_PUBLICA.csv", varnames(1) encoding(UTF-8) clear 
	*save "$docentes\docentes_2022_publica.dta",replace
	
	// Version publica
	use "$docentes\docentes_2022_publica.dta" ,clear
	
	// Version privada -> solo para obtener informacion de los autorizados
	*use "$docentes\docentes_2022_privada.dta" ,clear
	
	// Informar que base estas usando
	gen base = "pública" // privada o publica
	display "Estas usando la base de docentes en su versión $base"
	
	*Filtramos EE en funcionamiento
	keep if estado_estab==1
	
	*dropeamos variables que no se ocupan
	drop estado_estab persona
	
	*Variables de Interés 
	if base =="publica" {
		keep mrun rbd id_ifp id_ifs cod_ens_1 cod_ens_2 sector1 sector2 subsector1 subsector2 horas_aula horas1 horas2 tip_tit_id_1 tip_tit_id_2 nivel1 nivel2 cod_depe2 cod_reg_rbd cod_com_rbd rural_rbd esp_id_1 esp_id_2 id_itc tip_insti_id_1 tip_insti_id_2 grado*_1 grado*_2 autorizacion_docente
		
			order cod_reg_rbd cod_com_rbd cod_depe2 rural_rbd rbd mrun
	}
	else  if base =="privada" {
		keep doc_run rbd id_ifp id_ifs cod_ens_1 cod_ens_2 sector1 sector2 subsector1 subsector2 horas_aula horas1 horas2 tip_tit_id_1 tip_tit_id_2 nivel1 nivel2 cod_depe2 cod_reg_rbd cod_com_rbd rural_rbd esp_id_1 esp_id_2 id_itc tip_insti_id_1 tip_insti_id_2 grado*_1 grado*_2 autorizacion_docente
		
			order cod_reg_rbd cod_com_rbd cod_depe2 rural_rbd rbd doc_run
	}

	
	****************************************************************************
	*************************** Filtros base docentes **************************
	
**# Filtro: Establecimientos y Docentes

		* Mantenemos solo RBD urbanos
		keep if rural_rbd==0
		
		* Mantenemos solo docentes titulares y no reemplazantes
		drop if inlist(id_itc,3,7,12,19,20)
		
		* Destring de variables 
		quietly destring, dpcomma replace
		
	*Mantenemos a quienes ejercen como docente de aula, de forma primaria y a los que hacen clases en basica
	*Este se considera el universo de docentes
		keep if inlist(1,id_ifp,id_ifs)
		keep if inlist(110,cod_ens_1,cod_ens_2) // | inlist(310,cod_ens_1,cod_ens_2) esta sección la trasladaremos a otro codigo


	capture noisily codebook   mrun rbd
	capture noisily codebook   rbd doc_run
	*Tenemos un total de 114.483 docentes como universo final de basica usando ifp + ifs
	* Con un total de 112.225 únicos
	*considerando un total de 4,873 RBD como universo usando ifp + ifs
	
	****************************************************************************
	*************************** Criterios de Idoneidad *************************
	
**# Idoneidad Docente 

	*Versión 2
	**# Ed Básica
	// Condiciones para considerar 
	*La primera condicion (0) son docentes que hacen clases en el nivel de básica en alguna de estas asignaturas
	*La segunda condicion (1) son docentes que hacen clases y que además tienen la titulación según la ley n°....
	
	*condicion de titulacion
	gen titulo_pedagogia= 1 if (inlist(tip_tit_id_1,13,15,16) | inlist(tip_tit_id_2,13,15,16))
	gen titulo_media=1 if tip_tit_id_1==14|tip_tit_id_2==14
	
	*Condicion de hacer clases en 5to a 8vo basico
	forv j=1/2{
	forv i=5/8{
		gen clases_`i'_`j'=1 if cod_ens_`j'==110 & inlist(`i',grado1_`j',grado2_`j',grado3_`j',grado4_`j', grado5_`j', grado6_`j', grado7_`j', grado8_`j', grado9_`j', grado10_`j', grado11_`j', grado12_`j')
	}
	gen d_clases_5_8_`j'=1 if inlist(1,clases_5_`j', clases_6_`j', clases_7_`j', clases_8_`j')
	}
	drop clases_*
	* condicion de asignaturas (lenguaje, matemáticas, ciencias, historia & general)
	/* Explicacion:
	Genero una variable ido_bas1 o ido_bas2 según el subsector1 o 2 en que hace clases
	luego le asigno el 0 a todos aquellos que declaran hacer clases en alguna de las asignaturas de Ens. Basica explicadas arriba
	Asigno 1 a los Idóneos, que cumplen la condicion de hacer clases en el nivel & tienen la pedagogia en basica
	*/
	
	global listado1 inlist(subsector1,11001,11004,12001,12002,13001,13002,13003,13004,19001) 
	global listado2 inlist(subsector2,11001,11004,12001,12002,13001,13002,13003,13004,19001) 
	
	forv i=1/2{
	gen ido_bas`i'= 0 if inlist(subsector`i',11001,11004,12001,12002,13001,13002,13003,13004,19001) 
		replace ido_bas`i'=1 if titulo_pedagogia==1  & inlist(subsector`i',11001,11004,12001,12002,13001,13002,13003,13004,19001)
		replace ido_bas`i'=1 if titulo_media==1 & d_clases_5_8_`i'==1 & inlist(subsector`i',11001,11004,12001,12002,13001,13002,13003,13004,19001) 
	}
	
	egen tasa_idoneidad=rowmax(ido_bas1 ido_bas2)
	
	
	
	**# Tasa de Idoneidad
	** Descrición por sector **
	 *tab ido_bas // proporción de Idóneos es el 64%
	 tab ido_bas1 // proporción de Idóneos es el 69% aumentó a 78,8%
	 tab ido_bas2 // proporción de Idóneos es el 34% aumentó a 80,5% Este aumento es bastante grande
	 tab tasa_idoneidad // proporción de Idóneos es el 63,65% aumentó a 79,8%
	 tabstat tasa_idoneidad , by(cod_reg_rbd) save f( %9.4f)
	 
	 
	 
	 
**# Estadistica descriptiva - DOCENTES BASICA 

	*** Cantidad de docentes que ejercen en las asignaturas filtradas
	codebook mrun if tasa_idoneidad!=.

	*** Distribución de los docentes por dependencia 
	tab cod_depe2 if tasa_idoneidad!=.
	tab cod_reg_rbd if tasa_idoneidad!=.
	 
	 ** Para capturar la cantidad de establecimientos participantes debemos generar una aux a nivel de rbd
	 *** que capture si tiene docentes en alguna de estas áreas
	 
	 bys rbd: egen aux_contador_rbd=max(tasa_idoneidad)
	 codebook rbd if aux_contador_rbd!=.
	 
	 * Vemos como se comportan los docentes autorizados
	 capture noisily tab tasa_idoneidad autorizacion_docente
	 
	****************************************************************************
	*************************** Docentes Habilitados ***************************
	 
	 ****** NOTA: Esta seccion solo debe correrse para estadistica descriptiva
**# Docentes Habilitados
/*
	forv i=1/2{
	if `i'==1 {
	g doc_habilitado`i'=0 if $listado1 ==1 
		replace doc_habilitado`i'=2 if ido_bas`i'==0
	}
	else {
		g doc_habilitado`i'=0 if $listado2 ==1 
		replace doc_habilitado`i'=2 if ido_bas`i'==0
	}
	}

	egen tasa_habilitado=rowmax(doc_habilitado1 doc_habilitado2)
*/
	 
**# Estadística descriptiva Cargo Docente
{ //Esta seccion se traslado a 23081_figuras_hrs_aula
/*
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
	*Me gusta más la opcion 2
	*Para llegar a las 30 horas aula es necesario utilizar los docentes de basica y mediana
	*Además , para los mrun duplicados, dejamos la observacion con la mayor cantidad de horas aula
	****** NOTA!!!!: Hay docentes duplicados que suman más de 44 horas aula cuando se suma el rbd_i y el rbd_j
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
	*/
}

	********************************************************************************
**# Oferta de horas por RBD y Asignatura
	* Horas totales del establecimiento por cada subsector1 o subsector2*
	*Por subsector1
	preserve
	keep if inlist(subsector1,11001,11004,12001,12002,13001,13002,13003,13004,19001)
	collapse (sum) horas1 , by(rbd subsector1)
		
	tempfile ofta1
	save `ofta1',replace 
	restore
	
	preserve
			keep if inlist(subsector1,11001,11004,12001,12002,13001,13002,13003,13004,19001)
	collapse (sum) horas1 if ido_bas1==1, by(rbd subsector1)

	rename horas1 hrs_ido1
	tempfile ofta1_ido
	save `ofta1_ido',replace 
	restore

	
	*Por subsector2
	preserve
	keep if inlist(subsector2,11001,11004,12001,12002,13001,13002,13003,13004,19001)
	collapse (sum) horas2, by(rbd subsector2)
	rename subsector2 subsector1

	tempfile ofta2
	save `ofta2',replace 
	restore
	
	preserve
			keep if inlist(subsector2,11001,11004,12001,12002,13001,13002,13003,13004,19001)
	collapse (sum) horas2 if ido_bas2==1, by(rbd subsector2)
	rename subsector2 subsector1
	rename horas2 hrs_ido2

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
	
	use `ofta1',clear
	append using `ofta1_ido'
	append using `ofta2'
	append using `ofta2_ido'
	
		tempvar tot1_h1
	egen `tot1_h1'=total(horas1)
	
		display "horas 1 totales:"
	levelsof `tot1_h1'
	
********************************************************************************
	* Mantenemos sectores nucleares
	rename subsector1 subsector
	
	*ajustes del append
	recode horas1 horas2 hrs_ido1 hrs_ido2 (.=0)

	*el codebook arroja 4.862 establecimientos
	
**# Horas totales y Horas Lectivas
	*Horas disponibles del RBD
	
	
	///// SUPUESTO! las horas aula consideran lectivas + no lectivas, por lo que
	//// se utiliza el 65% de ellas como horas lectivas cronológicas mensuales
	
	
	*Acá tenemos el total de horas aula 
	
	gen hrs_aula2=horas1+horas2
	gen hrs_lect2=hrs_aula2*4*0.65
	
	gen hrs_aula_ido2=hrs_ido1+hrs_ido2
	gen hrs_lect_ido2=hrs_aula_ido2*4*0.65
	
	collapse (sum)   hrs_lect2 hrs_lect_ido2, by(rbd)
	
	rename (hrs_lect2 hrs_lect_ido2) (ofta_hrs2 ofta_hrs_ido2)
	
	*El sufijo 2 hace referencia al total de horas
	*el codebook arroja 4.862 establecimientos
	
	// Nivel basica para hacer el match con la demanda de horas
	gen cod_ense2=2

****************************************************************************


**# Merge Oferta y Demanda de EE

// Nota: La creacion de las horas demandadas esta en la carpeta.
	preserve
	use "dda_hrs_rbd_nivel_2022_38sem.dta",clear
	keep if cod_ense2==2
	keep if rural_rbd==0
	tempfile dda
	save `dda'
	restore

	merge 1:1 rbd cod_ense2 using `dda', keepusing(n_cursos dda_hrs_basica)
	rename _merge merge_dda
	*drop if _merge==1 //49 RBD con docentes pero sin matricula en el nivel. 
	*drop if _merge==2 //28 RBD con cursos pero sin docentes principales
	*Lo anterior es anomalo, y es una de limitaciones del modelo que existen establecimientos con discrepancias entre las clases y docentes
	
	*agregamos data administrativa
	merge 1:1 rbd using "$directorio\directorio_2022",  keepusing(cod_reg_rbd cod_com_rbd cod_depe2) keep(3)
	drop _merge
	
	tab merge_dda cod_depe2
	drop if merge_dda!=3
	drop merge_dda
	
	*Nos quedamos con 4.820 EE completos
	** Actualizacion nos quedamos con 4813 debido a la nueva condicion de docentes Idóneos

**# Cálculo del Deficit
	**# De horas a Docentes
	
	/// Nota: El deficit se entiende como la diferencia entre horas disponibles y
	/// horas demandadas
	
	* La transformacion de horas a n de docentes se basa en la mediana/promedio
	* de horas aula totales de los docentes, lo que se presenta en las figuras de
	* caracterizacion de horas aula de la seccion superior.
	
	*Dado que un docente hace 30 horas semanales y el 65% de estas son lectivas
	* Se divide por la multiplicación (30*0,65)
	
	*1 + 2
	gen def_total2=ofta_hrs2-dda_hrs_basica
	replace def_total2=def_total2/(30*0.65)
	
	gen def_ido2=ofta_hrs_ido2-dda_hrs_basica
		replace def_ido2=def_ido2/(30*0.65)
		
	**# establecimiento en situacion de deficit
	* Esta es una de las innovaciones que hicimos para el calculo del deficit
	* a nivel de establecimientos a diferencia de elige educar
	* Esta diferencia implica que tenemos SIEMPRE un n mas alto de deficit
	
	*horas 1+2
	gen d_def_tot2=1 if def_total2<0
		replace d_def_tot2=0 if def_total2>=0
	
	gen d_def_ido2=1 if def_ido2<0
		replace d_def_ido2=0 if def_ido2>=0
	
	* Redondeo del deficit segun situacion
	* Redondeamos debido a que no podemos tener de deficit 1,5 profes para un establecimiento
	
	replace def_total2=ceil(def_total2) if d_def_tot2==0
	replace def_total2=floor(def_total2) if d_def_tot2==1
	
	replace def_ido2=ceil(def_ido2) if d_def_ido2==0
	replace def_ido2=floor(def_ido2) if d_def_ido2==1

	save "230811_ofta_dda_basica_2022_38sem_doc_idoneo.dta",replace

	*save "ofta_dda_basica_2022",replace
	tempfile simulacion
	save `simulacion'
	
	
**# Base Final

	*use "230811_ofta_dda_basica_2022_38sem_doc_idoneo",clear
	use `simulacion',clear
	
	**# Graficos Horas1 y Horas totales
	**********
	** NOTA: LA MAYORIA DE LAS HORAS SE ENCUENTRAN EN HORAS 1 pero igual se considera horas 1 + horas 2 porque pequeñas horas hacen grandes diferencias
	
	
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
	legend(label(1 "Docentes Idóneos") label(2 "Docentes Idóneos disciplinar") region(fcolor(none) lcolor(none))) ///
	xtitle("Diferencia docentes estimada") ytitle("Densidad") ///
	graphregion(c(white)) xlabel(#10) ///
	xline(0,lcolor("235 60 70"*0.8))  
	
	*graph export "$output\230811_def_basica_2022_38sem.png",replace

	**# Graficos - Horas totales - BOXPLOT
	graph box def_total2 def_ido2, ///
	title("Distribución dif. estimada de docentes Educación Básica",color(black) margin(medium)) ///
	legend(label(1 "Docentes Idóneos") label(2 "Docentes Idóneos disciplinar")) ///
	graphregion(c(white)) ///
	box(1, color("15 105 180"*0.8)) ///
	box(2, color("235 60 70"*0.8)) ///
	nooutsides ytitle("Diferencia") ///
	legend(region(fcolor(none) lcolor(none))) ///
	note("Nota: Se excluyen los valores externos") ///
	yline(0, lpattern(solid) lcolor(black*0.6))
	
	*graph export "$output\230811_boxplot_def_basica_2022_38sem.png",replace
	

	
**# Tablas finales
	*Indicador por region y comuna
	bys cod_com_rbd: gen id_com=_n==1
	bys cod_reg_rbd: gen id_reg=_n==1
	
		
		*% de EE con déficit por región
		
	*tabstat d_def_tot1 d_def_ido1 d_def_tot2 d_def_ido2, by(cod_reg_rbd)
	tabstat d_def_tot2 d_def_ido2, by(cod_reg_rbd) s(mean) f(%9.4f)

	table cod_reg_rbd d_def_tot2
	table cod_reg_rbd d_def_ido2

	**# Total de docentes que faltan por comuna

/* DESCRIPCION TABLAS

sumamos a nivel de comuna la cantidad de docentes faltantes para los casos totales, docentes e Idóneos 

*/

	
	*1-NO NETEO! Comunal
	preserve	
	collapse (sum) def_total2 (first) cod_reg_rbd if d_def_tot2==1 , by(cod_com_rbd)
				export excel using "$output\230811_n_def_doc_38sem_2022_doc_idoneo.xlsx", sheet(basica_com,modify) firstrow(var) cell(B2)
	restore 

	preserve	
	collapse (sum) def_ido2 (first) cod_reg_rbd if d_def_ido2==1 , by(cod_com_rbd)
				export excel using "$output\230811_n_def_doc_38sem_2022_doc_idoneo.xlsx", sheet(basica_com,modify) firstrow(var) cell(F2)
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
	export excel using "$output\230811_n_def_doc_38sem_2022_doc_idoneo.xlsx", sheet(depe_basica,modify) firstrow(var) cell(B2)
	restore 

	preserve	
	collapse (sum) def_ido2 (first) cod_reg_rbd if d_def_ido2==1 , by(cod_com_rbd depe)
	sort depe cod_com_rbd
	export excel using "$output\230811_n_def_doc_38sem_2022_doc_idoneo.xlsx", sheet(depe_basica,modify) firstrow(var) cell(F2)
	restore 
	


