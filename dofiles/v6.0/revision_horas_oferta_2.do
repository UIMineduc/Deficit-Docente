/* MENSAJE INICIAL:
Autor: Alonso Arraño & Carla Zuñiga
Fecha: 12-02-24
Contenido:
Este código caracteriza las siguientes pedidas como:
-Cantidad de establecimientos sin todas las horas de asignaturas
-Distribución de docentes habilitados por dependencia
-Distribución del uso de las horas 
-% de docentes de reemplazo 

En otro código se revisará la cantidad de cursos y tamaños de cursos.
*/

**# Directorio

global Docentes "D:\OneDrive - Ministerio de Educación\0 0 Bases de datos - MINEDUC\Docentes\Cargos Docentes"


**# Carga de datos y configuraciones de bbdd
	use "$Docentes\docentes_2022_publica.dta" ,clear
	
	**Se filtra EE en funcionamiento
	keep if estado_estab==1
	
	**Se dropea variables que no se ocupan
	drop estado_estab persona
	
	**Se excluyen a los estbalecimientos particulares pagados
	drop if cod_depe2==3
	
	keep mrun rbd id_ifp id_ifs cod_ens_1 cod_ens_2 sector1 sector2 subsector1 subsector2 horas_aula horas1 horas2  horas_contrato tip_tit_id_* esp_id_* nivel* cod_depe2 cod_reg_rbd cod_com_rbd rural_rbd  id_itc nom_reg_rbd grado* 
	order cod_reg_rbd cod_com_rbd cod_depe2 rural_rbd rbd mrun 
	
	**Mantenemos solo RBD urbanos
	*Corregimos rural_rbd para que quede como en matricula
	replace rural_rbd=0 if inlist(rbd,10642,10673,10791,10827)
	keep if rural_rbd==0
	*hay 7447 establecimientos


	*Para evitar problemas para contar las horas se hace un reshape
	*Ahora los docentes pueden aparecer desde 1 a 4 veces en la base
	*dado que las observaciones de horas 2 se agregaron como obs nuevas
	
**# Establecimientos segun la cantidad de asignaturas sin horas disponibles
	
	preserve
		keep mrun rbd id_ifp id_ifs  cod_ens_1  sector1  subsector1  horas_contrato horas_aula horas1  tip_tit_id_1 esp_id_1 nivel1 cod_depe2 cod_reg_rbd cod_com_rbd rural_rbd  id_itc nom_reg_rbd grado*_1
		gen obs=1
		gen obs2="principal"

			destring ,replace
		
	tempfile horas_1
	save `horas_1'
	restore


		keep mrun rbd  id_ifp id_ifs cod_ens_2  sector2  subsector2  horas_contrato horas_aula horas2  tip_tit_id_2 esp_id_2 nivel2 cod_depe2 cod_reg_rbd cod_com_rbd rural_rbd  id_itc nom_reg_rbd grado*_2

		
		destring ,replace
		
		*Renombramos todos los terminos en 2 por 1
		rename *2  *1
		rename cod_depe1 cod_depe2
			gen obs=2
		gen obs2="secundario"
		
		append using `horas_1'

*Limpiamos la base para obtener las reales horas 2 reportadas
	sort rbd mrun obs
	drop if horas1==0 & obs==2
	drop if horas1==. & obs==2
	
*Eliminamos subsectores no asignados	
	drop if subsector1<0
	
* Etiquetamos las asignaturas nucleares

	gen asignatura=1 if inlist(subsector,31001,31004) // Lenguaje
	replace asignatura=2 if inlist(subsector,32001,32002) // Matemática
	replace asignatura=3 if inlist(subsector,35001,35002,35003,35004) // Ciencias
	replace asignatura=4 if inlist(subsector,33001,33002) // Historia
	replace asignatura=5 if inlist(subsector,11001,11004,12001,12002,13001,13002,13003,13004,19001)
	label var asignatura "Asignatura"
	label define asignaturalbl 1 "Lenguaje" 2 "Matematica" 3 "Ciencias" 4 "Historia" 5 "Basica"
	label values asignatura asignaturalbl

*dropeamos otras asignaturas y solo nos fijamos en las nucleares
	drop if asignatura==.

	**# Horas totales
*Haremos un collapse por rbd, subsector sumando las horas totales
	preserve
		collapse (sum) horas1 (first) cod_depe2, by(rbd asignatura )
		
		bys rbd: gen n_asignatura=_N
		bys rbd: gen id_rbd=_n

		table n_asignatura if id_rbd==1
		tabulate n_asignatura cod_depe2 if id_rbd==1, col
	restore
	
	**# Horas solo docentes
	*Haremos un collapse por rbd, subsector sumando las horas docente
	preserve
keep if id_ifp==1 | id_ifs==1
		collapse (sum) horas1 (first) cod_depe2, by(rbd asignatura )
		


		bys rbd: gen n_asignatura=_N
		bys rbd: gen id_rbd=_n

		table n_asignatura if id_rbd==1
		tabulate n_asignatura cod_depe2 if id_rbd==1, col
	restore



summ prop_horas,d
tabstat prop_horas, s(mean min max)

**# ¿composición de horas sobre las horas de contrato?

/* Esta sección se encuentra en R */

/*

	use "$Docentes\docentes_2022_publica.dta" ,clear
	
	**Se filtra EE en funcionamiento
	keep if estado_estab==1
	
	**Se dropea variables que no se ocupan
	drop estado_estab persona
	
	**Se excluyen a los estbalecimientos particulares pagados
	drop if cod_depe2==3
	
	keep mrun rbd id_ifp id_ifs cod_ens_1 cod_ens_2 sector1 sector2 subsector1 subsector2 horas1 horas2  horas_* tip_tit_id_* esp_id_* nivel* cod_depe2 cod_reg_rbd cod_com_rbd rural_rbd  id_itc nom_reg_rbd grado* 
	order cod_reg_rbd cod_com_rbd cod_depe2 rural_rbd rbd mrun 
	
	**Mantenemos solo RBD urbanos
	*Corregimos rural_rbd para que quede como en matricula
	replace rural_rbd=0 if inlist(rbd,10642,10673,10791,10827)
	keep if rural_rbd==0

	destring ,replace
	
keep if id_ifp==1 | id_ifs==1

replace horas_contrato=. if horas_contrato==0

foreach var of varlist horas_contrato horas_direct  horas_tec_ped horas_aula horas_dentro_estab horas_fuera_estab{
	replace `var'=. if `var'==0
	gen prop_`var'= `var'*100/horas_contrato
}

/* Notas: El análisis se basa en los docentes de aula, prim o sec == doc de aula,
esto es un total de 171570 docentes, este análisis cuenta a docentes de todas las asignaturas,
puede hacerse el filtro para tener solo las asignaturas necesarias*/ 
drop horas_contrato

summ prop*

twoway kdensity prop_horas_direct, lp(solid) lcolor("15 105 180"*0.8) lw(medthick) || ///
	kdensity prop_horas_tec_ped, lp(dash) lw(medthick) lcolor("235 60 70"*0.8) || ///
	kdensity prop_horas_aula , lp(solid) lw(medthick) lcolor("39 34 82"*0.8) || ///
	kdensity prop_horas_dentro_estab , lp(dash) lw(medthick) lcolor(bluishgray) || ///
	kdensity prop_horas_fuera_estab , lp(solid) lw(medthick) lcolor(lime) ///
	title("Densidad proporción de horas aula sobre horas contrato", color(black) margin(medium)) ///
	legend(label(1 "Directivas") label(2 "Tec. Ped.") label(3 "Aula") label(4 "Dentro Estab.") label(5 "Fuera Estab.") region(fcolor(none) lcolor(none)) rows(1) cols(5)) ///
	xtitle("Horas sobre Horas contrato") ///
	ytitle("Densidad", margin(right)) ///
	graphregion(c(white))	


graph box prop_horas_aula prop_horas_direct prop_horas_tec_ped  prop_horas_dentro_estab prop_horas_fuera_estab , nooutsides

*/

**# Análisis distribución horas de contrato 



	use "$Docentes\docentes_2022_publica.dta" ,clear
	
	**Filtramos EE en funcionamiento
	keep if estado_estab==1
	
	**Dropeamos variables que no se ocupan
	drop estado_estab persona
	
	**Se excluyen a los estbalecimientos particulares pagados
	drop if cod_depe2==3
	
	**Variables de Interés 
	keep mrun rbd id_ifp id_ifs cod_ens_1 cod_ens_2 sector1 sector2 subsector1 subsector2 horas* horas1 horas2 tip_tit_id_1 tip_tit_id_2 nivel1 nivel2 cod_depe2 cod_reg_rbd cod_com_rbd rural_rbd esp_id_1 esp_id_2 id_itc tip_insti_id_1 tip_insti_id_2 grado*_1 grado*_2 nom_com_rbd
	order cod_reg_rbd cod_com_rbd cod_depe2 rural_rbd rbd mrun

	**Mantenemos solo RBD urbanos
	replace rural_rbd=0 if inlist(rbd,10642,10673,10791,10827)
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
	
	*********
	*Idoneidad Docente
	*********

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
	
	tabstat ido_bas* tasa_especialidad 
	
	**# Cantidad de docentes habilitados por dependencia para enseñanza básica
	
	tabstat tasa_especialidad if tasa_especialidad==0, by(cod_depe2) s(n )
	tab tasa_especialidad cod_depe2 ,col
	
	tab tasa_especialidad tip_insti_id_1 if tasa_especialidad==0 ,row
	
	**Nota: 
	** La desagregacion por tip_insti_id_1 no es trivial porque la tasa de especialidad depende de:
	** Una combinación entre tipo de titulo, especialidad y nivel 
	

	
	
	
	
	
	
	
	
	
	
	

	
	
	