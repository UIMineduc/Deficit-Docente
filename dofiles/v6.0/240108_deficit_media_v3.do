* Autores: Alonso Arraño y Carla Zúñiga
* Fecha última modificación: 02-01-24
* Código: Cálculo de la dotación y déficit docente en las asignaturas de Lenguaje
* Matematicas, Ciencias e Historia en Enseñanza Media 


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
global Docentes "D:\OneDrive - Ministerio de Educación\0 0 Bases de datos - MINEDUC\Docentes\Cargos Docentes"
global Directorio "D:\OneDrive - Ministerio de Educación\BBDD\Directorio\2022"
global Sostenedores "D:\OneDrive - Ministerio de Educación\BBDD\Directorio Sostenedores\2022"
global SEP "D:\OneDrive - Ministerio de Educación\BBDD\SEP\2022"
global Output "$main/Output\2022\Nucleares\Media"



************************** Base de datos - Docentes ****************************

	use "$Docentes\docentes_2022_publica.dta" ,clear
	
	**Se filtra EE en funcionamiento
	keep if estado_estab==1
	
	**Se dropea variables que no se ocupan
	drop estado_estab persona
	
	**Se excluyen a los estbalecimientos particulares pagados
	drop if cod_depe2==3
	
	keep mrun rbd id_ifp id_ifs cod_ens_1 cod_ens_2 sector1 sector2 subsector1 subsector2 horas_aula horas1 horas2 tip_tit_id_* esp_id_* nivel* cod_depe2 cod_reg_rbd cod_com_rbd rural_rbd  id_itc nom_reg_rbd grado* 
	order cod_reg_rbd cod_com_rbd cod_depe2 rural_rbd rbd mrun 
	
	**Mantenemos solo RBD urbanos
	keep if rural_rbd==0

	**Mantenemos solo docentes titulares y no reemplazantes
	drop if inlist(id_itc,3,7,12,19,20)
		
	**Destring de variables 
	quietly destring, dpcomma replace

	**Mantenemos a quienes ejercen como docente de aula, de forma primaria y a los que hacen clases en basica/media. Este se considera el universo de docentes
	keep if inlist(1,id_ifp,id_ifs)
	
	**MODIFICACIÓN ESTABLECIMIENTOS TP QUE IMPARTEN ASIGNATURAS DEL PLAN DE FORMACIÓN GENERAL
	
	/// Para el cálculo de la dotación docente de asignaturas nucleares se incorporan 
	/// también los establecimientos TP ya que estos igual imparten las asignaturas 
	/// de formación general según lo establecido por el plan de estudios del 
	/// MINEDUC.
	keep if inlist(cod_ens_1,310,410,510,610,710,810,910) | inlist(cod_ens_2,310,410,510,610,710,810,910)
	
	keep if inlist(sector1,110,115,120,130,140,150,160,170,180,190,310,320,330,340,350,360,370,380,390,395) | inlist(sector2,110,115,120,130,140,150,160,170,180,190,310,320,330,340,350,360,370,380,390,395)

	
	*br cod_ens_1 subsector1 sector1 cod_ens_2 subsector2 sector2 horas1 horas2 if !inlist(cod_ens_1,110,310,410,510,610,710,810,910) 
	*sort subsector1
	
	**Se le asigna missing value a las observaciones que reportan horas para los subsectores incluidos en el análisis, pero que corresponden a otros códigos de enseñanza
	forv i=1/2{
	replace subsector`i'=. if !inlist(cod_ens_`i',310,410,510,610,710,810,910)
	}
	
	
	tab cod_ens_1 subsector1 if !inlist(cod_ens_1,310,410,510,610,710,810,910)
	
	codebook mrun rbd
	**Total de 54.134  de observaciones de docentes únicos y un total de 55.685 de docentes totales
	**Total de EE que imparten ed. media HC es de 2.420 RBD (sin reemplazos)
	
**************************** Criterios de Idoneidad ****************************
	
**# Idoneidad Docente

    **Condición de titulación
	**Titulado en media y especialidad de la asignatura
	gen titulo_leng=1 if (inlist(tip_tit_id_1,14,16) & inlist(esp_id_1,141,1605)) | ( inlist(tip_tit_id_2,14,16) &  inlist(esp_id_2,141,1605))
	
	gen titulo_mat=1 if (inlist(tip_tit_id_1,14,16) & inlist(esp_id_1,142,1606)) | 	( inlist(tip_tit_id_2,14,16) &  inlist(esp_id_2,142,1606))
	
	gen titulo_fisica=1 if (inlist(tip_tit_id_1,14) & inlist(esp_id_1,143)) |  (inlist(tip_tit_id_2,14) & inlist(esp_id_2,143))
	
	gen titulo_quimica=1 if (inlist(tip_tit_id_1,14) & inlist(esp_id_1,144)) |  (inlist(tip_tit_id_2,14) & inlist(esp_id_2,144))
	
	gen titulo_biologia=1 if (inlist(tip_tit_id_1,14) & inlist(esp_id_1,145,146)) |  (inlist(tip_tit_id_2,14) & inlist(esp_id_2,145,146))
	
	gen titulo_historia=1 if (tip_tit_id_1==14 & esp_id_1==148) | (tip_tit_id_2==14 & esp_id_2==148)
	

	**Condición de asignaturas
	**Explicación: Genero una variable ido_asignatura1 o ido_asignatura2 según el subsector1 o 2 en que hace clases (y la asignatura). Luego le asigno el 0 a todos aquellos que declaran hacer clases en alguna de las asignaturas. Asigno 1 a los Idóneos con especialidad, que cumplen la condición de tener el título de pedagogia en educación media y que tienen la especialidad de la asignatura que imparten
	

	**# Ed Media Lenguaje
	**Realiza o no clases en Lenguaje
	**Toma valor 0 si es que hace clases pero no tiene el título de la especialidad, y 1 si es que hace clases y tiene el título respectivo
	forv i=1/2{
	gen ido_leng`i'=0 if inlist(subsector`i',31001,31004)
	replace ido_leng`i'=1 if titulo_leng==1 & inlist(subsector`i',31001,31004)
	}
	
	
	**Tasa de especialidad en Lenguaje
	**Variable que agrupa subsector1 y subsector2 y asigna el valor máximo
	egen tasa_leng=rowmax(ido_leng1 ido_leng2)
	tab cod_depe2 if tasa_leng!=.
	tab cod_reg_rbd if tasa_leng!=.
	tab tasa_leng

	 
	**# Ed Media Matematica
    **Realiza o no clases en Matemática
	forv i=1/2{
	gen ido_mat`i'=0 if inlist(subsector`i',32001,32002)
	replace ido_mat`i'=1 if titulo_mat==1 & inlist(subsector`i',32001,32002)
	}
	
	**Tasa de especialidad en Matemática
	egen tasa_mat=rowmax(ido_mat1 ido_mat2)	
	tab cod_depe2 if tasa_mat!=.
	tab cod_reg_rbd if tasa_mat!=.
	tab tasa_mat

    **# Ed Media Ciencias
	**#Física
	forv i=1/2{
	gen ido_fisica`i'=0 if inlist(subsector`i',35003,35004)
	replace ido_fisica`i'=1 if titulo_fisica==1 & inlist(subsector`i',35003,35004)
	}
	
	egen tasa_fisica=rowmax(ido_fisica1 ido_fisica2)	
		
	**#Química
	forv i=1/2{
	gen ido_quimica`i'=0 if inlist(subsector`i',35002,35004)
	replace ido_quimica`i'=1 if titulo_quimica==1 & inlist(subsector`i',35002,35004)
	}
	
	egen tasa_quimica=rowmax(ido_quimica1 ido_quimica2)	
	
	**#Biología
	forv i=1/2{
	gen ido_biologia`i'=0 if inlist(subsector`i',35001,35004) 
	replace ido_biologia`i'=1 if titulo_biologia==1 & inlist(subsector`i',35001,35004)
	}

	egen tasa_biologia=rowmax(ido_biologia1 ido_biologia2)	
	
	**#Ciencias General
	forv i=1/2{
	egen ido_cs`i'=rowmax(ido_fisica`i' ido_quimica`i' ido_biologia`i')
		}

	egen tasa_cs=rowmax(ido_cs1 ido_cs2)
	tab cod_depe2 if tasa_cs!=.
	tab cod_reg_rbd if tasa_cs!=.
	
	**# Ed Media Historia
	forv i=1/2{
	gen ido_hist`i'=0 if inlist(subsector`i',33001,33002)
	replace ido_hist`i'=1 if titulo_historia==1 & inlist(subsector`i',33001,33002)
		}
		
	egen tasa_hist=rowmax(ido_hist1 ido_hist2)
	tab cod_depe2 if tasa_hist!=.
	tab cod_reg_rbd if tasa_hist!=.
	
	
	**Variable idoneidad 
	
	/// NOTA: Variable dummy que indica si el docente es idóneo para su asignatura o no,  
	/// es decir, agrupa docentes habilitados y docentes con la especialidad 
	/// (ido_asignatura=0 e ido_asignatura=1). Se usará para sumar las horas idóneas por
	/// asignatura más adelante
	
	/// la jornada laboral debería durar 36 horas uwu :(

	forv i=1/2{
	gen doc_ido`i'=1 if inlist(1,ido_leng`i',ido_mat`i',ido_cs`i',ido_hist`i')
	}
			
	egen max_ido=rowmax(doc_ido1 doc_ido2)

	foreach var of varlist  tasa_* {
	tab `var'
	 }
	 
	*lenguaje 75,12
	*mate 78,20
	*fisica 42,83
	*quimica 53,08
	*biologia 77,66
	*ciencias 70,79
	*historia 91,90
	tabstat tasa_*
	 
**# Estadistica descriptiva

	**Cantidad de docentes que ejercen en las asignaturas filtradas, ya sean habilitados o con la especialidad (0 o 1)
	codebook mrun if tasa_leng!=.

	**Distribución de los docentes por dependencia y región
	tab cod_depe2 if tasa_leng!=.
	tab cod_reg_rbd if tasa_leng!=.
	 
	tab cod_depe2 if tasa_mat!=.
	tab cod_reg_rbd if tasa_mat!=.
	
	tab cod_depe2 if tasa_cs!=.
	tab cod_reg_rbd if tasa_cs!=.
	
	tab cod_depe2 if tasa_hist!=.
	tab cod_reg_rbd if tasa_hist!=.

	 
	**Para capturar la cantidad de establecimientos participantes debemos generar una aux a nivel de rbd que capture si tiene docentes en alguna de estas áreas
	 bys rbd: egen aux_contador_rbd=max(tasa_leng)
	 codebook rbd if aux_contador_rbd!=.	 
	 


	 
	 
	 
******************************** Oferta de horas *******************************

	 
**# Oferta de horas por RBD y Asignatura
    **Horas totales del establecimiento por cada subsector1 o subsector2
	
	**Subsector1
	**Horas docentes idóneas
	preserve
	keep if inlist(subsector1,31001,31004,32001,32002,33001,33002,35001,35002,35003,35004)
	collapse (sum) horas1, by(rbd subsector1)
	tempfile ofta1
	save `ofta1',replace 
	restore
	
	**Horas docentes idóneas especialistas
	preserve
	keep if inlist(subsector1,31001,31004,32001,32002,33001,33002,35001,35002,35003,35004)
	collapse (sum) horas1 if doc_ido1==1, by(rbd subsector1)
	rename horas1 hrs_ido1
	tempfile ofta1_ido
	save `ofta1_ido',replace 
	restore
	
	**Por subsector2
	**Horas docentes idóneas
	preserve
	keep if inlist(subsector2,31001,31004,32001,32002,33001,33002,35001,35002,35003,35004)
	collapse (sum) horas2, by(rbd subsector2)
	rename subsector2 subsector1
	tempfile ofta2
	save `ofta2',replace 
	restore
	
	**Horas docentes idóneas especialistas
	preserve
	keep if inlist(subsector2,31001,31004,32001,32002,33001,33002,35001,35002,35003,35004)
	collapse (sum) horas2 if doc_ido2==1, by(rbd subsector2)
	rename subsector2 subsector1
	rename horas2 hrs_ido2
	tempfile ofta2_ido
	save `ofta2_ido',replace 
	restore
		
	**Hasta acá tenemos 2420 RBD
	**Agregamos la información de la cantidad de horas para cada oferta por RBD
	use `ofta1', clear
	append using `ofta1_ido'
	append using `ofta2'
	append using `ofta2_ido'
	
	**Mantenemos sectores nucleares
	rename subsector1 subsector
	
	**Ajustes del append
	recode horas1 horas2 hrs_ido1 hrs_ido2(.=0)
	

**# Horas totales y Horas Lectivas
	**Horas disponibles del RBD
		
	//// SUPUESTO: las horas aula consideran lectivas + no lectivas, por lo que
	//// se utiliza el 65% de ellas como horas lectivas cronológicas mensuales

	**Total de horas aula mensuales
	gen hrs_aula2=horas1+horas2
	gen hrs_lect2=hrs_aula2*4*0.65 

	
	gen hrs_aula_ido2=hrs_ido1+hrs_ido2
	gen hrs_lect_ido2=hrs_aula_ido2*4*0.65

	
	**Generamos Asignaturas 
	gen asignatura=1 if inlist(subsector,31001,31004) // Lenguaje
	replace asignatura=2 if inlist(subsector,32001,32002) // Matemática
	replace asignatura=3 if inlist(subsector,35001,35002,35003,35004) // Ciencias
	replace asignatura=4 if inlist(subsector,33001,33002) // Historia
	label var asignatura "Asignatura"
	label define asignaturalbl 1 "Lenguaje" 2 "Matematica" 3 "Ciencias" 4 "Historia"
	label values asignatura asignaturalbl
	
	collapse (sum) hrs_lect2 hrs_lect_ido2, by(rbd asignatura)
	
	rename ( hrs_lect2 hrs_lect_ido2) ( ofta_hrs2 ofta_hrs_ido2 )

	**El codebook arroja 2.405 rbd
	**Se agrega cod_ense de Nivel basica para hacer el match con la demanda de horas
	gen cod_ense2=5
	
	tempvar aux1
	bys asignatura: egen `aux1'=total(ofta_hrs_ido2)
	tab `aux1' asignatura
		
***************************** Oferta y Demanda EE ******************************

**# Merge Oferta y Demanda de EE
	preserve
	use "$Data\dda_hrs_rbd_nivel_2022_38sem_v1.dta",clear
	keep if cod_ense2==5 & rural_rbd==0
	tempfile dda
	save `dda'
	restore 
    
	merge m:1 rbd cod_ense2 using `dda', keepusing( n_cursos dda_hrs_*)
	drop if _merge==1 //19 RBD con docentes pero sin matricula
	drop if _merge==2 //25 RBD con matrícula pero sin docente
	drop _merge
	drop dda_hrs_basica
	
	 
	**Codebook 2.399 rbd
	**Agregamos data administrativa
	merge m:1 rbd using "$Directorio\directorio_2022", nogen keep(3) keepusing(cod_reg_rbd cod_com_rbd cod_depe2) 


****************************** Cálculo del déficit *****************************	

	
**# Transformación de horas a Docentes

	/// Nota: El déficit se entiende como la diferencia entre horas disponibles y
	/// horas demandadas

	**Cálculo del déficit idóneo y déficit idóneo especialista
	local x=1
	foreach var in leng mat cs hist{
	gen def_`var'2=ofta_hrs2 - dda_hrs_`var' if asignatura==`x'
	replace def_`var'2=(def_`var'2)/(28*0.65)
	
	gen def_ido_`var'2=ofta_hrs_ido2- dda_hrs_`var' if asignatura==`x'
	replace def_ido_`var'2=(def_ido_`var'2)/(28*0.65)
	local x=`x'+1

	**Cálculo de la demanda de horas transformado en docentes
	replace dda_hrs_`var'=dda_hrs_`var'/(28*0.65)	
	}
	
**# Establecimientos en situación de déficit por asignatura

    **Establecimientos con déficit idóneo y déficit idóneo especialista
	local x=1
	foreach var in leng mat cs hist{
	*horas 1+2
	gen d_def_`var'2=1 if def_`var'2<0 & asignatura==`x'
	replace d_def_`var'2=0 if def_`var'2>=0 & asignatura==`x'
	
	gen d_def_ido_`var'2=1 if def_ido_`var'2<0 & asignatura==`x'
	replace d_def_ido_`var'2=0 if def_ido_`var'2>=0 & asignatura==`x'
	local x=`x'+1
	}

	
**# Redondeo del deficit de docentes
	
	**Déficit idóneo e idóneo especialista
	foreach var in leng mat cs hist{	
	replace def_`var'2=ceil(def_`var'2) if d_def_`var'2==0
	replace def_`var'2=floor(def_`var'2) if d_def_`var'2==1
	
	
	replace def_ido_`var'2=ceil( def_ido_`var'2) if d_def_ido_`var'2==0
	replace def_ido_`var'2=floor( def_ido_`var'2) if d_def_ido_`var'2==1
	}


	
**# Graficos Minuta
	
	**Cambiar titulo del gráfico de forma manual
	local j=1
foreach var in leng mat cs hist{
	local z: label (asignatura) `j'
	display "graficando la variable `var' con etiqueta `z' "
	twoway kdensity def_`var'2, lp(solid) lcolor("15 105 180"*0.8) lw(medthick) || ///
	kdensity def_ido_`var'2, lp(dash) lw(medthick) lcolor("235 60 70"*0.8) ///
	title("Densidad de la dif. estimada de docentes en `z'", color(black) margin(medium)) ///
	legend(label(1 "Docentes Totales") label(2 "Docentes Idoneo") region(fcolor(none) lcolor(none))) ///
	xtitle("Diferencia docentes estimada") ///
	ytitle("Densidad") ///
	graphregion(c(white))
	graph export "$Output\240103_def_doc_`var'_2022_distr_v1.png", replace
	local j = `j' +1
	}
	
	**Listado de variables de interés 
	global listado "def_leng2 def_ido_leng2 def_mat2 def_ido_mat2 def_cs2 def_ido_cs2 def_hist2  def_ido_hist2"
	
**# Figuras finales box plot media
		
	**Figura Final
	graph box def_leng2 def_mat2 def_cs2 def_hist2, ///
	legend(rows(4) label(1 "Lenguaje") ///
	label(2 "Matemáticas") ///
	label(3 "Ciencias") ///
	label(4 "Historia") ///
	region(fcolor(none) lcolor(none))) ///
	graphregion(c(white)) nooutsides ///
	ytitle("Diferencia") ///
	yline(0, lpattern(solid) lcolor(black*0.6)) ///
	note("Nota: Se excluyen los valores externos") ///
	box(1, color("247 87 100"*0.9)) ///
	box(2, color("15 105 180"*0.9)) ///
	box(3, color("95 187 155"*0.9)) ///
	box(4, color("247 168 21"*0.9))
	graph export "$Output\240103_def_doc_media_2022_boxplot_v1.png", replace
	
	
	graph box def_leng2 def_mat2 def_cs2 def_hist2, ///
	title("Distribución dif. estimada de docentes en enseñanza media", color(black) margin(l-7)) ///
	subtitle("por asignatura") ///
	legend(label(1 "Lenguaje") ///
	label(2 "Matemáticas") ///
	label(3 "Ciencias") ///
	label(4 "Historia") ///
	region(fcolor(none) lcolor(none))) ///
	graphregion(c(white)) nooutsides ///
	ytitle("Diferencia") ///
	yline(0, lpattern(solid) lcolor(black*0.6)) ///
	note("Se excluyen los valores externos") ///
	box(1, color("247 87 100"*0.9)) ///
	box(2, color("15 105 180"*0.9)) ///
	box(3, color("95 187 155"*0.9)) ///
	box(4, color("247 168 21"*0.9))
	*graph export "$Output\240103_def_doc_media_2022_boxplot_v1.png",replace
	
	**Opciones para gráficos sin formato cem
	**title("Distribución diferencia estimada de docentes en Ens. Media") subtitle("por asignatura") ///


**# Base final
	save "$Data\240103_ofta_dda_media_2022_v1.dta",replace
	
	
	
****************************** Resultados finales ******************************	
	
	use "$Data\240103_ofta_dda_media_2022_v1",clear

**# Se generan tramos de docentes faltantes para calcular el % de establecimientos con déficit por tramos
	foreach var in leng mat cs hist{	
	tab def_`var'2 if d_def_`var'2==1	    
	summarize def_`var'2 if d_def_`var'2==1,d 
	}
	
	
	**Distribución de establecimientos con déficit docente   
	foreach var in leng mat cs hist{	
	preserve        
	keep if d_def_`var'2==1
	gsort -def_`var'2
	replace def_`var'2=def_`var'2*-1 if d_def_`var'2==1
	summarize def_`var'2 if d_def_`var'2==1,d 

    
	local p25= `r(p25)'
	local p50= `r(p50)'
	local p75= `r(p75)'
	
	
	histogram def_`var'2 if d_def_`var'2==1, width(1) discrete ///
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
	xlabel(1 5 10 15 20)
	graph export "$Output\distribucion_docentes_faltantes_`var'.png" , replace
	restore
	}

	
	**Variable dicotómica para cada tramo
	foreach var in leng mat cs hist{	 	    
	gen tramo1_`var'=0 if def_`var'2!=.
	replace tramo1_`var'=1 if def_`var'2 >-3 & d_def_`var'2==1
	
	gen tramo2_`var'=0 if def_`var'2!=.
	replace tramo2_`var'=1 if def_`var'2 <=-3 & def_`var'2 >-6 & d_def_`var'2==1
	
	gen tramo3_`var'=0 if def_`var'2!=.
	replace tramo3_`var'=1 if def_`var'2 <=-6 & d_def_`var'2==1
	}

	**Porcentaje de EE con déficit por tramos	
	foreach var in leng mat cs hist{	
	tabstat tramo1_`var' tramo2_`var' tramo3_`var', s(mean) f(%9.4f)
	}

	foreach var in leng mat cs hist {
	preserve
	collapse (mean) tramo1_`var' tramo2_`var' tramo3_`var'
	export excel using "$Output\240103_porcent_def_media_tramo_2022_v1.xlsx", sheet(EE_def_tramo_`var',modify) firstrow(var) cell(B2)
	restore
	}
	

	
**# Porcentaje de EE con déficit por región y asignatura
	foreach var in leng mat cs hist {
	display "Mostrando la situación para la asignatura `var'"
	tabstat d_def_`var'2 d_def_ido_`var'2, by(cod_reg_rbd) s(mean) f(%9.4f)
	*table  cod_reg_rbd d_def_`var'2 
	tab cod_reg_rbd d_def_ido_`var'2 
	}
    
	
	local x=2
	foreach var in leng mat cs hist {
	local letter: word `x' of `c(ALPHA)'
	display "`letter'"
	preserve
	collapse (mean) d_def_`var'2 d_def_ido_`var'2 , by(cod_reg_rbd)
	export excel using "$Output\240103_porcent_def_media_reg_2022_v1.xlsx", sheet(EE_def_region,modify) firstrow(var) cell("`letter'2")
	restore
	local x=`x'+5
	}
	
	 
	
**# Total de docentes que faltan por región y asignatura
	foreach var in leng mat cs hist{
	tabstat def_`var'2 if d_def_`var'2==1 , by(cod_reg_rbd) s(sum)
	}
	foreach var in leng mat cs hist{
	tabstat def_ido_`var'2 if d_def_ido_`var'2==1 , by(cod_reg_rbd) s(sum)
	}

	
	foreach var in leng mat cs hist{
	preserve	
	collapse (sum) def_`var'2 if d_def_`var'2==1 , by(cod_reg_rbd)
	export excel using "$Output\240103_def_media_reg_2022_v1.xlsx", sheet(reg_`var',modify) firstrow(var) cell(B2)
	restore 

	preserve	
	collapse (sum) def_ido_`var'2 if d_def_ido_`var'2==1 , by(cod_reg_rbd)
	export excel using "$Output\240103_def_media_reg_2022_v1.xlsx", sheet(reg_`var',modify) firstrow(var) cell(G2)
	restore 
	
	preserve	
	collapse (sum) dda_hrs_`var' , by(cod_reg_rbd)
	export excel using "$Output\240103_def_media_reg_2022_v1.xlsx", sheet(reg_`var',modify) firstrow(var) cell(K2)
	restore 
	
	}	
	
	
	
	

**# Total de docentes que faltan por dependencia y asignatura
	
	**Definición de Dependencia
	gen depe=.
	replace depe=1 if cod_depe2==1
	replace depe=2 if inlist(cod_depe2,2,4)
	replace depe=3 if cod_depe2==5
	label define depe 1 "Público" 2 "Subvencionado" 3 "SLEP"
	label values depe depe
	

	
	foreach var in leng mat cs hist{
	preserve	
	collapse (sum) def_`var'2 if d_def_`var'2==1 , by(depe)
	sort depe
	export excel using "$Output\240103_def_media_depe_2022_v1.xlsx", sheet(depe_`var',modify) firstrow(var) cell(B2)
	restore 

	preserve	
	collapse (sum) def_ido_`var'2 if d_def_ido_`var'2==1 , by(depe)
	sort depe
	export excel using "$Output\240103_def_media_depe_2022_v1.xlsx", sheet(depe_`var',modify) firstrow(var) cell(F2)
	restore 
	
	preserve
	collapse (sum) dda_hrs_`var' , by(depe)
	sort depe
	export excel using "$Output\240103_def_media_depe_2022_v1.xlsx", sheet(depe_`var',modify) firstrow(var) cell(K2)
	restore 		
	}	 
	


**# Porcentaje de EE con déficit por dependencia y asignatura
	foreach var in leng mat cs hist {
	display "Mostrando la situación para la asignatura `var'"
	tabstat d_def_`var'2 d_def_ido_`var'2, by(depe) s(mean) f(%9.4f)
	tab cod_reg_rbd d_def_ido_`var'2 
	}
    
	
	local x=2
	foreach var in leng mat cs hist {
	local letter: word `x' of `c(ALPHA)'
	display "`letter'"
	preserve
	collapse (mean) d_def_`var'2 d_def_ido_`var'2 , by(depe)
	export excel using "$Output\240103_porcent_def_media_depe_2022_v1.xlsx", sheet(EE_def_depe,modify) firstrow(var) cell("`letter'2")
	restore
	local x=`x'+5
	}	
	
	

**# Porcentaje de EE con déficit por SLEP	
	merge m:1 rbd using "$Sostenedores\rbd_slep_2022.dta"
	drop if _merge==2
	drop _merge
	
	
	
	
	
	**Variable dicotómica para cada SLEP y asignatura
	foreach var in leng mat cs hist {
	gen andalien_sur_`var'=0 if depe==4 & def_`var'2!=.
	replace andalien_sur_`var'=1 if nom_sle=="ANDALIÉN SUR" & d_def_`var'2==1
	
	gen atacama_`var'=0 if depe==4 & def_`var'2!=.
	replace atacama_`var'=1 if nom_sle=="ATACAMA" & d_def_`var'2==1

	gen barrancas_`var'=0 if depe==4 & def_`var'2!=.
	replace barrancas_`var'=1 if nom_sle=="BARRANCAS" & d_def_`var'2==1

	gen chinchorro_`var'=0 if depe==4 & def_`var'2!=.
	replace chinchorro_`var'=1 if nom_sle=="CHINCHORRO" & d_def_`var'2==1

	gen colchagua_`var'=0 if depe==4 & def_`var'2!=.
	replace colchagua_`var'=1 if nom_sle=="COLCHAGUA" & d_def_`var'2==1

	gen costa_araucania_`var'=0 if depe==4 & def_`var'2!=.
	replace costa_araucania_`var'=1 if nom_sle=="COSTA ARAUCANÍA" & d_def_`var'2==1

	gen gab_mistral_`var'=0 if depe==4 & def_`var'2!=.
	replace gab_mistral_`var'=1 if nom_sle=="GABRIELA MISTRAL" & d_def_`var'2==1

	gen huasco_`var'=0 if depe==4 & def_`var'2!=.
	replace huasco_`var'=1 if nom_sle=="HUASCO" & d_def_`var'2==1

	gen llanquihue_`var'=0 if depe==4 & def_`var'2!=.
	replace llanquihue_`var'=1 if nom_sle=="LLANQUIHUE" & d_def_`var'2==1

	gen pto_cordillera_`var'=0 if depe==4 & def_`var'2!=.
	replace pto_cordillera_`var'=1 if nom_sle=="PUERTO CORDILLER" & d_def_`var'2==1
	
	gen valparaiso_`var'=0 if depe==4 & def_`var'2!=.
	replace valparaiso_`var'=1 if nom_sle=="VALPARAÍSO" & d_def_`var'2==1
}
	
	
	
	foreach var in leng mat cs hist{	
	tabstat andalien_sur_`var' atacama_`var' barrancas_`var' chinchorro_`var' colchagua_`var' costa_araucania_`var' gab_mistral_`var' huasco_`var' llanquihue_`var' pto_cordillera_`var' valparaiso_`var', s(mean) f(%9.4f)
	}

	foreach var in leng mat cs hist {
	preserve
	collapse (mean) andalien_sur_`var' atacama_`var' barrancas_`var' chinchorro_`var' colchagua_`var' costa_araucania_`var' gab_mistral_`var' huasco_`var' llanquihue_`var' pto_cordillera_`var' valparaiso_`var'
	export excel using "$Output\240103_porcent_def_media_depe_2022_v1.xlsx", sheet(EE_def_depe_`var',modify) firstrow(var) cell(B2)
	restore
	}
	
	
	
	
	**Se agrega información sobre la concentración de alumnos prioritarios por rbd para la distribución de horas lectivas y no lectivas
	merge m:1 rbd using "$SEP\rbd_vulnerabilidad_2022"
	drop if _merge!=3
	drop _merge	
	
	
	

	
	
	
	
	
	
	
	
	
	