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
	*use "$docentes\docentes_2022_publica.dta" ,clear
	
	// Version privada -> solo para obtener informacion de los autorizados
	use "$docentes\docentes_2022_privada.dta" ,clear
	
	// Informar que base estas usando
	gen base = "privada" // privada o publica
	display "Estas usando la base de docentes en su versión $base"
	
	*Filtramos EE en funcionamiento
	quietly{ 
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
	}
**# Análisis
		* Mantenemos solo RBD urbanos
		keep if rural_rbd==0
		
		* Mantenemos solo docentes titulares y no reemplazantes
		drop if inlist(id_itc,3,7,12,19,20)
		
		* Destring de variables 
		quietly destring, dpcomma replace
		
	*Mantenemos a quienes ejercen como docente de aula, de forma primaria y a los que hacen clases en basica
	*Este se considera el universo de docentes
		keep if inlist(1,id_ifp,id_ifs)
	*Dado que las horas aulas es para un docente representativo utilizaremos el mismo valor para un docente de media y basica
	*Además, dejaremos la observacion con las horas aula mas altas en caso de exisitr docentes repetidos
		keep if inlist(110,cod_ens_1,cod_ens_2) | inlist(310,cod_ens_1,cod_ens_2)
	
	
	capture noisily codebook   mrun rbd
	capture noisily codebook   rbd doc_run

	
	
	 
**# Estadística descriptiva Cargo Docente
	*Revision de horas aula
	gen aux=horas1+horas2
	summarize aux,d

	gsort doc_run -horas_aula
	by doc_run: egen sum_aux=total(aux)


	*Ordenamos las observacioens por la mayor cantidad de horas aula para c/ run
	gsort doc_run -horas_aula
	by doc_run: gen id=_n
	by doc_run: gen obs=_N
	keep if id==1
	
	summarize sum_aux,d
	
	*Distribución horas_aula 
	*opcion 1*
	summarize horas_aula,d 
	local mediana= `r(p50)'
	
	kdensity horas_aula, lcolor("15 105 180"*0.8) ///
	xline(`mediana',lcolor("235 60 70"*0.8))  ///
	graphregion(c(white)) ///
	xtitle("Horas de aula") ///
	ytitle("Densidad") ///
	xlabel(0(4)44)
	
	**Formato CEM
	*title("Distribución horas de aula, Ed. básica",color(black) margin(medium)) ///
	*note("Nota: Se presentanHoras cronológicas") ///
	
	
	*opcion 2
	*Me gusta más la opcion 2
	*Para llegar a las 30 horas aula es necesario utilizar los docentes de basica y mediana
	*Además , para los mrun duplicados, dejamos la observacion con la mayor cantidad de horas aula
	****** NOTA!!!!: Hay docentes duplicados que suman más de 44 horas aula cuando se suma el rbd_i y el rbd_j
	summarize horas_aula,d 
	local mediana= `r(p50)'
	
	histogram horas_aula, width(1) discrete ///
	xline(`mediana',lcolor("235 60 70"*0.8))  ///
	color( "0 112 150") ///
	lcolor( "0 112 150") ///
	lwidth(thin) ///
	fin(inten60) ///
	graphregion(c(white)) ///
	xtitle("Horas de aula",margin(small)) ///
	ytitle("Densidad") ///
	xlabel(0 5 10 15 20 25 30 35 40 44) ///
	note("Nota: Horas cronológicas" "Nota 2: La línea roja representa el 50% de la distribución")
	
	graph export "${output}\distribucion_horas_aula.png" , replace
	*	title("Distribución horas de aula en básica y media", color(black) margin(medium)) ///
	
	**# Caracterizacion Docentes Basica
	
	graph box horas_aula, nooutsides

	
	table id_itc cod_depe2
	
	** Tablas
	tab cod_depe2
	tab sector1
	tab id_ifs
