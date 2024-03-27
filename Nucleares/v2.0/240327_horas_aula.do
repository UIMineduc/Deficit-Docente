* Autores: Alonso Arraño y Carla Zúñiga
* Fecha última modificación: 27-03-24
* Código: Análisis de las horas destinadas a funciones de aula para determinar 
* el docente promedio a usar en la transformación de horas a docentes (docente representativo)



**# Configuración
clear all
set more off
graph set window fontface "Calibri light" // Dejamos calibri light como formato predeterminado 

global main "D:\OneDrive - Ministerio de Educación\Proyectos\2024\Déficit docente"
global Data "$main/Data\2023"
global Plan "$main/Plan de Estudios"
global Matricula "D:\OneDrive - Ministerio de Educación\BBDD\Matricula\2023"
global Docentes "D:\OneDrive - Ministerio de Educación\BBDD\Docentes\2023"
global Directorio "D:\OneDrive - Ministerio de Educación\BBDD\Directorio\2023"
global Sostenedores "D:\OneDrive - Ministerio de Educación\BBDD\Directorio Sostenedores\2023"
global SEP "D:\OneDrive - Ministerio de Educación\BBDD\SEP\2023"
global Output "$main/Output\2023\Nucleares\Descriptivos"



**# 1. BBDD Cargo docente 

	use "$Docentes\docentes_2023_publica.dta" ,clear
	
	**Se une base de directorio para identificar a los establecimientos con matrícula
	merge m:1 rbd using "$Directorio\directorio_2023_edit.dta"
	drop if _merge!=3
	drop _merge

	**Se filtra EE en funcionamiento
	keep if estado_estab==1 & matricula==1
		
	**Se excluyen a los establecimientos particulares pagados
	drop if cod_depe2==3
	
	keep mrun rbd id_ifp id_ifs cod_ens_1 cod_ens_2 sector1 sector2 subsector1 subsector2 horas_aula horas1 horas2 tip_tit_id_1 tip_tit_id_2 nivel1 nivel2 cod_depe2 cod_reg_rbd cod_com_rbd rural_rbd esp_id_1 esp_id_2 id_itc tip_insti_id_1 tip_insti_id_2 grado*_1 grado*_2 horas_*
	order cod_reg_rbd cod_com_rbd cod_depe2 rural_rbd rbd mrun
	
	**Se mantienen solo RBD urbanos
	keep if rural_rbd==0
	
	**Destring de variables 
	quietly destring, dpcomma replace
	
	**Se mantienen solamente a los establecimientos que imparten Ed. Básica y Media
	keep if inlist(cod_ens_1,110,310,410,510,610,710,810,910) | inlist(cod_ens_2,110,310,410,510,610,710,810,910)
	**Se mantienen solamente a los sectores de análisis (asignaturas nucleares y transversales)
	keep if inlist(sector1,110,115,120,130,140,150,160,170,180,190,310,320,330,340,350,360,370,380,390,395) | inlist(sector2,110,115,120,130,140,150,160,170,180,190,310,320,330,340,350,360,370,380,390,395)
	

	**Se le asigna missing value a las observaciones que reportan horas para los subsectores incluidos en el análisis, pero que corresponden a otros códigos de enseñanza, lo mismo para los códigos de enseñanza incluidos en el análisis pero que tienen otros subsectores
	forv i=1/2{
	replace horas`i'=. if !inlist(cod_ens_`i',110,310,410,510,610,710,810,910) | !inlist(sector`i',110,115,120,130,140,150,160,170,180,190,310,320,330,340,350,360,370,380,390,395)
	}
		
	**Se mantienen solo docentes titulares y no reemplazantes
	drop if inlist(id_itc,3,7,12,19,20)	
	
	**Se mantienen a quienes ejercen como docente de aula, como función principal o secundaria
	keep if inlist(1,id_ifp,id_ifs)	
	
	
**# 2. Revisión de horas destinadas a funciones de aula
	
	**Se crea una variable que suma las horas impartidas por docentes que son considerados en el análisis, es decir, las horas de los subsectores 1 y 2 de asignaturas de educación básica y plan de formación general de educación media HC, TP y Artística.
	forv i=1/2{
	replace horas`i'=0 if horas`i'==.
	}
	gen horas_docente=horas1+horas2
	egen prom=mean(horas_docente)
	egen mediana=median(horas_docente)	
	
	**Se ordenan las observaciones por la mayor cantidad de horas aula para c/ run
	gsort mrun -horas_docente
	by mrun: egen sum_horas_docente=total(horas_docente)
	by mrun: gen id=_n
	by mrun: gen obs=_N
	summarize sum_horas_docente,d
	
	**Definición de Dependencia
	gen depe=.
	replace depe=1 if cod_depe2==1
	replace depe=2 if inlist(cod_depe2,2,4)
	replace depe=3 if cod_depe2==5
	label define depe 1 "Municipal" 2 "Subvencionado" 3 "SLEP"
	label values depe depe
	

	
**# 3. Gráficos - Distribución horas aula
	
	**Distribución horas destinadas a funciones de Aula
	**NOTA: Hay docentes duplicados que suman más de 44 horas aula cuando se suma el rbd_i y el rbd_j
	**NOTA 2: Se dejan docentes duplicados como si fueran dos docentes diferentes (no se suman las horas)
	summarize horas_docente,d 
	local mediana= `r(p50)'
	local media= `r(mean)' 
	
	histogram horas_docente, width(1) discrete ///
	xline(`mediana',lcolor("235 60 70"*0.8))  ///
	color( "0 112 150") ///
	lcolor( "0 112 150") ///
	lwidth(thin) ///
	fin(inten60) ///
	graphregion(c(white)) ///
	xtitle("Horas destinadas a funciones de Aula ",margin(small)) ///
	ytitle("Densidad") ///
	xlabel(0 5 10 15 20 25 30 35 40 44) ///
	note("Nota: Horas cronológicas" "Nota 2: La línea roja representa el 50% de la distribución")
	graph export "$Output\distribucion_horas_aula.png" , replace
	*title("Distribución horas destinadas a funciones de Aula en Ens. Básica y Media", color(black) margin(medium)) ///
	
	
	**Distribución horas destinadas a funciones de Aula por dependencia		
	forv i=1/3{	
	summarize horas_docente if depe==`i',d 
	local mediana= `r(p50)'
	histogram horas_docente if depe==`i', width(1) discrete ///
	xline(`mediana',lcolor("235 60 70"*0.8))  ///
	color( "0 112 150") ///
	lcolor( "0 112 150") ///
	lwidth(thin) ///
	fin(inten60) ///
	graphregion(c(white)) ///
	xtitle("Horas destinadas a funciones de Aula ",margin(small)) ///
	ytitle("Densidad") ///
	xlabel(0 5 10 15 20 25 30 35 40 44) ///
	note("Nota: Horas cronológicas" "Nota 2: La línea roja representa el 50% de la distribución")
	graph export "$Output\distribucion_horas_aula_depe_`i'.png" , replace
	*title("Distribución horas destinadas a funciones de Aula en Ens. Básica y Media por dependencia", color(black) margin(medium)) ///
	
	}	
	
	twoway kdensity horas_docente if depe==1, lp(solid) lcolor("15 105 180"*0.8) lw(medthick)  || ///
	kdensity horas_docente if depe==2 , lp(dash) lw(medthick) lcolor("235 60 70"*0.8) ///
	title("Densidad horas destinadas a funciones de aula",color(black) margin(medium) ) ///
	legend(label(1 "Municipal") label(2 "Subvencionado") region(fcolor(none) lcolor(none))) ///
	xtitle("Horas destinadas a funciones de aula") ytitle("Densidad") ///
	graphregion(c(white)) xlabel(#10)
	graph export "$Output\densidad_horas_aula.png" , replace


	
