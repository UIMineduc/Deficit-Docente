* Autores: Alonso Arraño y Carla Zúñiga
* Fecha última modificación: 02-01-24

* Nota: Esta versión del cálculo excluye a los establecimientos particulares pagados ya que se decidió no incluirlos en el análisis debido a la falta de datos.


**# Configuracion
clear all
graph set window fontface "Calibri light" // Dejamos calibri light como formato predeterminado 


global main "D:\OneDrive - Ministerio de Educación\Proyectos\Déficit docente"
global Data "$main/Data"
global Matricula "D:\OneDrive - Ministerio de Educación\BBDD\Matricula\2022"
global Docentes "D:\OneDrive - Ministerio de Educación\BBDD\Docentes\2022"
global Directorio "D:\OneDrive - Ministerio de Educación\BBDD\Directorio\2022"
global Output "$main/Output\2022\Nucleares"



************************** Base de datos - Docentes ****************************

	use "$Docentes\docentes_2022_publica.dta" ,clear

	*Filtramos EE en funcionamiento
	keep if estado_estab==1
	
	*dropeamos variables que no se ocupan
	drop estado_estab persona
	
	**Se excluyen a los estbalecimientos particulares pagados
	drop if cod_depe2==3
	
	keep mrun rbd id_ifp id_ifs cod_ens_1 cod_ens_2 sector1 sector2 subsector1 subsector2 horas_aula horas1 horas2 tip_tit_id_1 tip_tit_id_2 nivel1 nivel2 cod_depe2 cod_reg_rbd cod_com_rbd rural_rbd esp_id_1 esp_id_2 id_itc tip_insti_id_1 tip_insti_id_2 grado*_1 grado*_2 horas_*
	order cod_reg_rbd cod_com_rbd cod_depe2 rural_rbd rbd mrun
	
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
	keep if inlist(cod_ens_1,110,310,410,510,610,710,810,910) | inlist(cod_ens_2,110,310,410,510,610,710,810,910)
	keep if inlist(sector1,110,115,120,130,140,150,160,170,180,190,310,320,330,340,350,360,370,380,390,395) | inlist(sector2,110,115,120,130,140,150,160,170,180,190,310,320,330,340,350,360,370,380,390,395)

	
	br horas_aula cod_ens_1 subsector1 sector1 horas1 cod_ens_2 subsector2 sector2 horas2 if !inlist(sector2,110,115,120,130,140,150,160,170,180,190,310,320,330,340,350,360,370,380,390,395) | !inlist(cod_ens_2,110,310,410,510,610,710,810,910) 
	sort cod_ens_2
	sort subsector1
	sort horas2
	
	
	**Se le asigna missing value a las observaciones que reportan horas para los subsectores incluidos en el análisis, pero que corresponden a otros códigos de enseñanza, lo mismo para los códigos de enseñanza incluidos en el análisis pero que tienen otros subsectores
	forv i=1/2{
	replace horas`i'=. if !inlist(cod_ens_`i',110,310,410,510,610,710,810,910) | !inlist(sector`i',110,115,120,130,140,150,160,170,180,190,310,320,330,340,350,360,370,380,390,395)
	}
	
	**Se crea una variable que suma las horas impartidas por docentes que son considerados en el análisis, es decir las horas de los subsectores 1 y 2 de asignaturas de educación básica y plan de formación general de educación media HC, TP y Artística.
	forv i=1/2{
	replace horas`i'=0 if horas`i'==.
	}
	gen horas_docente=horas1+horas2
	egen prom=mean(horas_docente)
	egen mediana=median(horas_docente)
	
	
**# Revisión de horas destinadas a funciones de aula

	*Ordenamos las observaciones por la mayor cantidad de horas aula para c/ run
	gsort mrun -horas_docente
	*gsort mrun -horas_contrato
	by mrun: egen sum_horas_docente=total(horas_docente)
	by mrun: gen id=_n
	by mrun: gen obs=_N
	*keep if id==1
	*replace sum_horas_docente=44 if sum_horas_docente>44
	
	summarize sum_horas_docente,d

	
	**Distribución horas destinadas a funciones de Aula
	**Además, para los mrun duplicados, dejamos la observacion con la mayor cantidad de horas aula
	**NOTA: Hay docentes duplicados que suman más de 44 horas aula cuando se suma el rbd_i y el rbd_j
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
	*	title("Distribución horas destinadas a funciones de Aula en básica y media", color(black) margin(medium)) ///
	
	//	xline(`media',lcolor("0 0 0"*0.8))  ///
	
	
	
	sort sum_horas_docente
