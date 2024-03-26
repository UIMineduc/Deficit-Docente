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

**Nota2: Este código sólo analizará la población de cargo docente con filtros menores

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
		
// Para ver las horas haremos un append de las horas2 de cargo docente

*Limpiamos la base para obtener las reales horas 2 reportadas
	sort rbd mrun obs
	drop if horas1==0 & obs==2
	drop if horas1==. & obs==2
	
	
**# ¿Who is teaching? Horas de aula distintas de docentes

*Revision horas de aula distinto de 0 pese a tener funcion primaria o secundaria distinta de docentes

gen caso1=0
	replace caso1=1 if id_ifp!=1 & id_ifs!=1 & horas1!=0
	
*Todos en cargo docente*
tab caso1 cod_depe2, col

**definimos asignaturas
gen asignatura=1 if inlist(subsector,31001,31004) // Lenguaje
	replace asignatura=2 if inlist(subsector,32001,32002) // Matemática
	replace asignatura=3 if inlist(subsector,35001,35002,35003,35004) // Ciencias
	replace asignatura=4 if inlist(subsector,33001,33002) // Historia
	replace asignatura=5 if inlist(subsector,11001,11004,12001,12002,13001,13002,13003,13004,19001)
	label var asignatura "Asignatura"
	label define asignaturalbl 1 "Lenguaje" 2 "Matematica" 3 "Ciencias" 4 "Historia" 5 "Basica"
	label values asignatura asignaturalbl


	*solo los de asignaturas nucleares*
preserve
*dropeamos otras asignaturas y solo nos fijamos en las nucleares
	drop if asignatura==.

tab caso1 cod_depe2, col
restore






*Proporcion de horas para todos los docentes de aula

bys rbd mrun: egen horas_tot=total(horas1)
gen prop_horas=horas_tot*100/horas_contrato


* caso 0 es docentes de aula 
preserve
keep if caso1==0
	
twoway kdensity prop_horas if cod_depe2==1 & caso1==0, lp(solid) lcolor("15 105 180"*0.8) lw(medthick) || ///
	kdensity prop_horas if cod_depe2==2 & caso1==0, lp(dash) lw(medthick) lcolor("235 60 70"*0.8) || ///
	kdensity prop_horas if cod_depe2==5 & caso1==0, lp(dash) lw(medthick) lcolor("39 34 82"*0.8) ///
	title("Densidad proporción de horas aula sobre horas contrato", color(black) margin(medium)) ///
	legend(label(1 "Municipal") label(2 "Subvencionado") label(3 "SLEP") region(fcolor(none) lcolor(none)) rows(1)) ///
	xtitle("Horas Aula sobre Horas contrato") ///
	ytitle("Densidad") ///
	graphregion(c(white))	
	
restore


preserve
keep if caso1==0 & asignatura!=.
	
twoway kdensity prop_horas if cod_depe2==1 & caso1==0, lp(solid) lcolor("15 105 180"*0.8) lw(medthick) || ///
	kdensity prop_horas if cod_depe2==2 & caso1==0, lp(dash) lw(medthick) lcolor("235 60 70"*0.8) || ///
	kdensity prop_horas if cod_depe2==5 & caso1==0, lp(dash) lw(medthick) lcolor("39 34 82"*0.8) ///
	title("Densidad proporción de horas aula sobre horas contrato", color(black) margin(medium)) ///
	legend(label(1 "Municipal") label(2 "Subvencionado") label(3 "SLEP") region(fcolor(none) lcolor(none)) rows(1)) ///
	xtitle("Horas Aula sobre Horas contrato") ///
	ytitle("Densidad") ///
	graphregion(c(white))	
	
restore


**# Docentes de reemplazo

	**caracterizamos docentes titulares y reemplazantes
	gen reemplazo=1 if inlist(id_itc,3,7,12,19,20)
	replace reemplazo=0 if reemplazo!=1

*Reemplazo en todo cargo docente
tab reemplazo

*reemplazo en docentes de aula
tab reemplazo if caso1==0

*reemplazo en docentes de aula /basica
tab reemplazo if caso1==0 & cod_ens_1==110
tab reemplazo if caso1==0 & asignatura==5

*reemplazo en docentes de aula /media
tab reemplazo if caso1==0 & inrange(cod_ens_1,211,910)
tab reemplazo if caso1==0 &  inlist(asignatura,1,2,3,4)



