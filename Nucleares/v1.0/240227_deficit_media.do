* Autores: Alonso Arraño y Carla Zúñiga
* Fecha última modificación: 27-02-24
* Código: Cálculo de la dotación y déficit docente en las asignaturas de Lenguaje
* Matematicas, Ciencias e Historia en Enseñanza Media 


**# Configuración
clear all
set more off
graph set window fontface "Calibri light" // Dejamos calibri light como formato predeterminado 


**Añadimos fecha para guardar los archivos
global suffix: display %tdCCYY-NN-DD =daily("`c(current_date)'", "DMY")
display "$suffix"


global main "D:\OneDrive - Ministerio de Educación\Proyectos\2024\Déficit docente"
global Data "$main/Data\2023"
global Plan "$main/Plan de Estudios"
global Matricula "D:\OneDrive - Ministerio de Educación\BBDD\Matricula\2023"
global Docentes "D:\OneDrive - Ministerio de Educación\BBDD\Docentes\2023"
global Directorio "D:\OneDrive - Ministerio de Educación\BBDD\Directorio\2023"
global Sostenedores "D:\OneDrive - Ministerio de Educación\BBDD\Directorio Sostenedores\2023"
global SEP "D:\OneDrive - Ministerio de Educación\BBDD\SEP\2023"
global Output "$main/Output\2023\Nucleares\Media"



************************** Base de datos - Docentes ****************************

	use "$Docentes\docentes_2023_publica.dta" ,clear
	
	**Se filtra EE en funcionamiento
	keep if estado_estab==1
	
	**Se dropea variables que no se ocupan
	drop estado_estab persona
	
	**Se excluyen a los establecimientos particulares pagados
	drop if cod_depe2==3
	
	keep mrun rbd id_ifp id_ifs cod_ens_1 cod_ens_2 sector1 sector2 subsector1 subsector2 horas_aula horas1 horas2 tip_tit_id_* esp_id_* nivel* cod_depe2 cod_reg_rbd cod_com_rbd rural_rbd  id_itc nom_reg_rbd grado* 
	order cod_reg_rbd cod_com_rbd cod_depe2 rural_rbd rbd mrun 
	
	**Se mantienen solo RBD urbanos
	keep if rural_rbd==0
	
	**Destring de variables 
	quietly destring, dpcomma replace	
	
	**Se mantienen solamente los establecimientos que imparten Ed. media en sus tres modalidades (HC, TP y artística)
	keep if inlist(cod_ens_1,310,410,510,610,710,810,910) | inlist(cod_ens_2,310,410,510,610,710,810,910)
		
	**Se le asigna missing value a las observaciones que reportan horas para los subsectores incluidos en el análisis, pero que corresponden a otros códigos de enseñanza (para que al momento de hacer el collapse estas horas no se incorporen a la oferta de horas)
	forv i=1/2{
	replace subsector`i'=. if !inlist(cod_ens_`i',310,410,510,610,710,810,910)
	tab cod_ens_`i' subsector`i' if !inlist(cod_ens_`i',310,410,510,610,710,810,910)
	}


	**Cantidad de rbds y docentes antes de aplicar los filtros
	codebook rbd mrun
	**El codebook hasta aquí da cuenta de 2.442 establecimientos que imparten Ens. media (incluyendo reemplazos)
	**Total de 65.226 docentes repetidos y 63.721 docentes únicos

	**Se excluyen aquellos establecimientos que no poseen info para todas las asignaturas
	sort rbd
	bys rbd: gen aux_leng=0
	bys rbd: replace aux_leng=1 if inlist(subsector1,31001,31004)
	bys rbd: replace aux_leng=1 if inlist(subsector2,31001,31004)	
	sort rbd aux_leng
	bys rbd: replace aux_leng=aux_leng[_N]

	bys rbd: gen aux_mat=0
	bys rbd: replace aux_mat=1 if inlist(subsector1,32001,32002)
	bys rbd: replace aux_mat=1 if inlist(subsector2,32001,32002)
	sort rbd aux_mat
	bys rbd: replace aux_mat=aux_mat[_N]

	bys rbd: gen aux_cs=0
	bys rbd: replace aux_cs=1 if inlist(subsector1,35001,35002,35001,35004)
	bys rbd: replace aux_cs=1 if inlist(subsector2,35001,35002,35001,35004)	
	sort rbd aux_cs
	bys rbd: replace aux_cs=aux_cs[_N]
	
	bys rbd: gen aux_hist=0
	bys rbd: replace aux_hist=1 if inlist(subsector1,33001,33002)
	bys rbd: replace aux_hist=1 if inlist(subsector2,33001,33002)	
	sort rbd aux_hist
	bys rbd: replace aux_hist=aux_hist[_N]
	
	bys rbd: gen aux=0
	replace aux=1 if aux_leng==1 & aux_mat==1 & aux_cs==1 & aux_hist==1

	preserve
	bys rbd: keep if _n==1
	tab aux // 2.293 establecimientos tienen información para las 4 asignaturas
	restore

	**Se dejan solamente a los establecimientos con información en las 4 asignaturas
	keep if aux==1 // codebook indica 2.293 establecimientos
	drop aux*

	**Se filtra para mantener solo a los docentes titulares y no reemplazantes (pero sin eliminar esas observaciones para mantener a los mismos rbds que poseen info para las 4 asignaturas)
	forv i=1/2{
	replace horas`i'=. if inlist(id_itc,3,7,12,19,20)
	}
	
	**Se filtra para mantener solo a los docentes que ejercen como docente de aula, como función principal o secundaria (nuevamente se imputa missing value y no se eliminan aquellas observaciones que no cumplen con función principal o secundaria docente de aula para mantener mismos rbds)
	forv i=1/2{
	replace horas`i'=. if !inlist(1,id_ifp,id_ifs)
	}
	
	**Se genera un indicador de docente que identifica si un docente es idóneo o bien no es considerado como docente a pesar de que tenga horas asignadas a algún subsector (esto puede ocurrir si realiza clases pero tiene una función principal o secundaria distinta a docente de aula, o si es un docente de reemplazo)
	gen docente=0
	replace docente=1 if !inlist(id_itc,3,7,12,19,20) & inlist(1,id_ifp,id_ifs)
		
	**Cantidad de rbds y docentes una vez aplicados los filtros
	codebook mrun rbd
	**Total de EE que imparten ed. media es de 2.293 RBD
	**Total de 62.242 docentes únicos y un total de 63.635 de docentes totales 
	
**************************** Criterios de Idoneidad ****************************
	
**# Idoneidad Docente

    **Condición de titulación
	**Titulado en media y especialidad de la asignatura
	gen titulo_leng=1 if (inlist(tip_tit_id_1,14,16) & inlist(esp_id_1,141,1605)) & docente==1 | (inlist(tip_tit_id_2,14,16) & inlist(esp_id_2,141,1605)) & docente==1
	
	gen titulo_mat=1 if (inlist(tip_tit_id_1,14,16) & inlist(esp_id_1,142,1606)) & docente==1 | (inlist(tip_tit_id_2,14,16) & inlist(esp_id_2,142,1606)) & docente==1
	
	gen titulo_fisica=1 if (inlist(tip_tit_id_1,14) & inlist(esp_id_1,143)) & docente==1 | (inlist(tip_tit_id_2,14) & inlist(esp_id_2,143)) & docente==1
	
	gen titulo_quimica=1 if (inlist(tip_tit_id_1,14) & inlist(esp_id_1,144)) & docente==1 | (inlist(tip_tit_id_2,14) & inlist(esp_id_2,144)) & docente==1
	
	gen titulo_biologia=1 if (inlist(tip_tit_id_1,14) & inlist(esp_id_1,145,146)) & docente==1 | (inlist(tip_tit_id_2,14) & inlist(esp_id_2,145,146)) & docente==1
	
	gen titulo_historia=1 if (tip_tit_id_1==14 & esp_id_1==148) & docente==1 | (tip_tit_id_2==14 & esp_id_2==148) & docente==1
	

	**Condición de asignaturas 
	**Explicación: Genero una variable ido_asignatura1 o ido_asignatura2 según el subsector1 o 2 en que hace clases (y la asignatura). Luego le asigno el 0 a todos aquellos que declaran hacer clases en alguna de las asignaturas y que sean considerados como docentes idóneos (habilitados o especialistas). Asigno 1 a los Idóneos con especialidad, que cumplen la condición de tener el título de pedagogia en educación media y que tienen la especialidad de la asignatura que imparten
	
    **# Ed Media Lenguaje
	forv i=1/2{
	gen ido_leng`i'=0 if inlist(subsector`i',31001,31004) & docente==1
	replace ido_leng`i'=1 if titulo_leng==1 & inlist(subsector`i',31001,31004) & docente==1
	}

	**# Ed Media Matematica
	forv i=1/2{
	gen ido_mat`i'=0 if inlist(subsector`i',32001,32002) & docente==1
	replace ido_mat`i'=1 if titulo_mat==1 & inlist(subsector`i',32001,32002) & docente==1
	}
	
    **# Ed Media Ciencias
	**#Física
	forv i=1/2{
	gen ido_fisica`i'=0 if inlist(subsector`i',35003,35004) & docente==1
	replace ido_fisica`i'=1 if titulo_fisica==1 & inlist(subsector`i',35003,35004) & docente==1
	}	

	**#Química
	forv i=1/2{
	gen ido_quimica`i'=0 if inlist(subsector`i',35002,35004) & docente==1
	replace ido_quimica`i'=1 if titulo_quimica==1 & inlist(subsector`i',35002,35004) & docente==1
	}	

	**#Biología
	forv i=1/2{
	gen ido_biologia`i'=0 if inlist(subsector`i',35001,35004) & docente==1
	replace ido_biologia`i'=1 if titulo_biologia==1 & inlist(subsector`i',35001,35004) & docente==1
	}	
	
	**#Ciencias
	forv i=1/2{
	egen ido_cs`i'=rowmax(ido_fisica`i' ido_quimica`i' ido_biologia`i')
	}
	
	**# Ed Media Historia
	forv i=1/2{
	gen ido_hist`i'=0 if inlist(subsector`i',33001,33002) & docente==1
	replace ido_hist`i'=1 if titulo_historia==1 & inlist(subsector`i',33001,33002) & docente==1
	}	
	
	**Tasa de especialidad
	foreach var in leng mat fisica quimica biologia cs hist{	
	egen tasa_`var'=rowmax(ido_`var'1 ido_`var'2)
	}		
	
	**Variable docente con especialidad
	forv i=1/2{
	gen doc_ido`i'=1 if inlist(1,ido_leng`i',ido_mat`i',ido_cs`i',ido_hist`i')
	}
		
		
**# Estadistica descriptiva		
	**Tasa de docentes con especialidad por asignatura
	foreach var of varlist tasa_* {
	tab `var'
	 }
	 
	*lenguaje 73,44
	*mate 76,71
	*fisica 40,47
	*quimica 52,36
	*biologia 76,16
	*ciencias 69,62
	*historia 91,49
	tabstat tasa_*
	
	
	**SE UNE BASE SLEP (ESTO FALTA AGREGAR AL CÓDIGO DE 2022)
	merge m:1 cod_com_rbd using "$SLEP\directorio_slep_2018_2024.dta"
	drop if _merge==2
	drop _merge
	replace nombre_slep="" if cod_depe2!=5
	replace agno_slep=. if cod_depe2!=5
	replace cod_slep=. if cod_depe2!=5	
	
	
	
	
	**Tasa de docentes con especialidad por asignatura, dependencia y región
	preserve
	replace cod_depe2=2 if cod_depe2==4
	foreach var in leng mat cs hist{	
	tab cod_depe2 tasa_`var', row
	tab cod_reg_rbd tasa_`var', row	
	}
	restore
	
	preserve
	replace cod_depe2=2 if cod_depe2==4
	collapse (mean) tasa_leng tasa_mat tasa_fisica tasa_quimica tasa_biologia tasa_cs tasa_hist
	export excel using "$Output\240227_tasa_especialidad_media_2023_v1.xlsx", sheet(tot,modify) firstrow(var) cell(B2)
	restore		
	
	preserve
	replace cod_depe2=2 if cod_depe2==4
	collapse (mean) tasa_leng tasa_mat tasa_fisica tasa_quimica tasa_biologia tasa_cs tasa_hist, by(cod_depe2)	
	export excel using "$Output\240227_tasa_especialidad_media_2023_v1.xlsx", sheet(depe,modify) firstrow(var) cell(B2)
	restore		
	
	preserve
	replace cod_depe2=2 if cod_depe2==4
	collapse (mean) tasa_leng tasa_mat tasa_fisica tasa_quimica tasa_biologia tasa_cs tasa_hist, by(cod_reg_rbd)	
	export excel using "$Output\240227_tasa_especialidad_media_2023_v1.xlsx", sheet(region,modify) firstrow(var) cell(B2)
	restore		
	
	preserve
	collapse (mean) tasa_leng tasa_mat tasa_fisica tasa_quimica tasa_biologia tasa_cs tasa_hist if cod_depe2==5, by(agno_slep nombre_slep)	
	export excel using "$Output\240227_tasa_especialidad_media_2023_v1.xlsx", sheet(slep,modify) firstrow(var) cell(B2)
	restore		
	
	
	

	**Cantidad de docentes que ejercen en las asignaturas filtradas, ya sean habilitados o con la especialidad (0 o 1)
	foreach var in leng mat cs hist{	
	codebook mrun if tasa_`var'!=.
	}
	
	**Distribución de los docentes por dependencia y región
	foreach var in leng mat cs hist{	
	tab cod_depe2 if tasa_`var'!=.
	tab cod_reg_rbd if tasa_`var'!=.
	}
	 
	 
******************************** Oferta de horas *******************************

	 
**# Oferta de horas por RBD y Asignatura
    **Horas totales del establecimiento por cada subsector1 o subsector2
	
	**Subsector1
	**Oferta de horas docentes idóneas
	preserve
	keep if inlist(subsector1,31001,31004,32001,32002,33001,33002,35001,35002,35003,35004)
	collapse (sum) horas1, by(rbd subsector1)
	tempfile ofta1
	save `ofta1',replace 
	restore
	
	**Oferta de horas docentes idóneas especialistas
	preserve
	keep if inlist(subsector1,31001,31004,32001,32002,33001,33002,35001,35002,35003,35004)
	collapse (sum) horas1 if doc_ido1==1, by(rbd subsector1)
	rename horas1 hrs_ido1
	tempfile ofta1_ido
	save `ofta1_ido',replace 
	restore
	
	**Por subsector2
	**Oferta de horas docentes idóneas
	preserve
	keep if inlist(subsector2,31001,31004,32001,32002,33001,33002,35001,35002,35003,35004)
	collapse (sum) horas2, by(rbd subsector2)
	rename subsector2 subsector1
	tempfile ofta2
	save `ofta2',replace 
	restore
	
	**Oferta de horas docentes idóneas especialistas
	preserve
	keep if inlist(subsector2,31001,31004,32001,32002,33001,33002,35001,35002,35003,35004)
	collapse (sum) horas2 if doc_ido2==1, by(rbd subsector2)
	rename subsector2 subsector1
	rename horas2 hrs_ido2
	tempfile ofta2_ido
	save `ofta2_ido',replace 
	restore
		
	**Hasta acá tenemos 2.293 RBD
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
	rename (hrs_lect2 hrs_lect_ido2) (ofta_hrs2 ofta_hrs_ido2)

	**El codebook arroja 2.293 rbd
	**Se agrega cod_ense de Nivel media para hacer el match con la demanda de horas
	gen cod_ense2=5
	
	bys asignatura: egen aux=total(ofta_hrs_ido2)
	tab aux asignatura
	

***************************** Oferta y Demanda EE ******************************

**# Merge Oferta y Demanda de EE
	preserve
	use "$Data\dda_hrs_rbd_nivel_2023_38sem_v1.dta",clear
	keep if cod_ense2==5 & rural_rbd==0
	tempfile dda
	save `dda'
	restore 
    
	merge m:1 rbd cod_ense2 using `dda', keepusing(n_cursos dda_hrs_*)
	drop if _merge==1 //16 RBD con docentes pero sin matricula
	drop if _merge==2 //153 RBD con matrícula pero sin docente
	drop _merge dda_hrs_basica
	
	 
	**Codebook 2.289 rbd
	**Agregamos data administrativa
	merge m:1 rbd using "$Directorio\directorio_2023", nogen keep(3) keepusing(cod_reg_rbd cod_com_rbd cod_depe2) 


****************************** Cálculo del déficit *****************************	

	
**# Transformación de horas a Docentes

	/// Nota: El déficit se entiende como la diferencia entre horas disponibles y
	/// horas demandadas y se deja expresado tanto en horas como en docentes

	**Cálculo del déficit idóneo y déficit idóneo especialista
	local x=1
	foreach var in leng mat cs hist{
	gen def_`var'2=ofta_hrs2 - dda_hrs_`var' if asignatura==`x'
	gen def_`var'2_doc=(def_`var'2)/(28*0.65)
	
	gen def_ido_`var'2=ofta_hrs_ido2- dda_hrs_`var' if asignatura==`x'
	gen def_ido_`var'2_doc=(def_ido_`var'2)/(28*0.65)
	local x=`x'+1
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
	replace def_`var'2_doc=ceil(def_`var'2_doc) if d_def_`var'2==0
	replace def_`var'2_doc=floor(def_`var'2_doc) if d_def_`var'2==1
	
	
	replace def_ido_`var'2_doc=ceil(def_ido_`var'2_doc) if d_def_ido_`var'2==0
	replace def_ido_`var'2_doc=floor(def_ido_`var'2_doc) if d_def_ido_`var'2==1
	}

**# Gráficos - Horas totales - DENSIDAD
	local j=1
    foreach var in leng mat cs hist{
	local z: label (asignatura) `j'
	display "graficando la variable `var' con etiqueta `z' "
	twoway kdensity def_`var'2, lp(solid) lcolor("15 105 180"*0.8) lw(medthick) || ///
	kdensity def_ido_`var'2, lp(dash) lw(medthick) lcolor("235 60 70"*0.8) ///
	title("Densidad de la dif. estimada de horas docentes en `z'", color(black) margin(medium)) ///
	legend(label(1 "Idóneos") label(2 "Con especialidad") region(fcolor(none) lcolor(none))) ///
	xtitle("Diferencia horas docentes estimada") ytitle("Densidad") ///
	graphregion(c(white)) xline(0,lcolor("235 60 70"*0.8))  
	graph export "$Output\240227_def_doc_`var'_2023_38sem.png", replace
	local j = `j' +1
	}
	
	**Listado de variables de interés 
	global listado "def_leng2 def_ido_leng2 def_mat2 def_ido_mat2 def_cs2 def_ido_cs2 def_hist2 def_ido_hist2"
	
**# Gráficos - Horas totales - BOXPLOT
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
	graph export "$Output\240227_boxplot_def_media_2023_38sem.png",replace
	*Sacamos esto por politica CEM
	*title("Distribución dif. estimada de horas docentes Ens. Media") subtitle("por asignatura"), color(black) margin(medium)) ///
	
	
**# Gráficos EE con Superávit
	foreach var in leng mat cs hist{	
	summarize def_`var'2_doc if d_def_`var'2==0,d
    summarize def_`var'2_doc if def_`var'2_doc>0,d
    
	local p25= `r(p25)'
	local p50= `r(p50)'
	local p75= `r(p75)'
	
	histogram def_`var'2_doc if def_`var'2_doc>0, width(1) discrete ///
	xline(`p25',lcolor("235 60 70"*0.8))  ///
	xline(`p50',lcolor("235 60 70"*0.8))  ///
	xline(`p75',lcolor("235 60 70"*0.8))  ///	
	color( "0 112 150") ///
	lcolor( "0 112 150") ///
	lwidth(thin) ///
	fin(inten60) ///
	graphregion(c(white)) ///
	xtitle("Cantidad de docentes sobrantes",margin(small)) ///
	ytitle("Densidad") name(histo_`var') title("`var'")
	graph export "$Output\240227_distribucion_docentes_superavit_`var'.png" , replace
	}

	graph combine histo_leng histo_mat histo_cs histo_hist, ycommon xcommon
	graph export "$Output\240227_distribucion_docentes_superavit_media.png" , replace
	
	save "$Data\240227_ofta_dda_media_2023_v1.dta",replace
	
	
****************************** Resultados finales ******************************	
	
	use "$Data\240227_ofta_dda_media_2023_v1",clear
	
**# Porcentaje de EE con déficit por región y asignatura
	foreach var in leng mat cs hist {
	display "Mostrando la situación para la asignatura `var'"
	tabstat d_def_`var'2 d_def_ido_`var'2, by(cod_reg_rbd) s(mean) f(%9.4f)
	tab cod_reg_rbd d_def_`var'2
	}
    
	local x=2
	foreach var in leng mat cs hist {
	local letter: word `x' of `c(ALPHA)'
	display "`letter'"
	preserve
	collapse (mean) d_def_`var'2 d_def_ido_`var'2 , by(cod_reg_rbd)
	export excel using "$Output\240227_porcent_def_media_reg_2023_v1.xlsx", sheet(EE_def_region,modify) firstrow(var) cell("`letter'2")
	restore
	local x=`x'+5
	}
	
**# Total de horas docentes que faltan por región y asignatura
	foreach var in leng mat cs hist{
	tabstat def_`var'2 if d_def_`var'2==1 , by(cod_reg_rbd) s(sum)
	tabstat def_ido_`var'2 if d_def_ido_`var'2==1 , by(cod_reg_rbd) s(sum)
	}

	
	foreach var in leng mat cs hist{
	preserve	
	collapse (sum) def_`var'2 if d_def_`var'2==1 , by(cod_reg_rbd)
	export excel using "$Output\240227_def_media_reg_2023_v1.xlsx", sheet(reg_`var',modify) firstrow(var) cell(B2)
	restore 

	preserve	
	collapse (sum) def_ido_`var'2 if d_def_ido_`var'2==1 , by(cod_reg_rbd)
	export excel using "$Output\240227_def_media_reg_2023_v1.xlsx", sheet(reg_`var',modify) firstrow(var) cell(G2)
	restore 
	
	preserve	
	collapse (sum) dda_hrs_`var' , by(cod_reg_rbd)
	export excel using "$Output\240227_def_media_reg_2023_v1.xlsx", sheet(reg_`var',modify) firstrow(var) cell(K2)
	restore 
	}	
	
	
**# Porcentaje de EE con déficit por dependencia y asignatura

	**Definición de Dependencia
	gen depe=.
	replace depe=1 if cod_depe2==1
	replace depe=2 if inlist(cod_depe2,2,4)
	replace depe=3 if cod_depe2==5
	label define depe 1 "Municipal" 2 "Subvencionado" 3 "SLEP"
	label values depe depe

	foreach var in leng mat cs hist {
	display "Mostrando la situación para la asignatura `var'"
	tabstat d_def_`var'2 d_def_ido_`var'2, by(depe) s(mean) f(%9.4f)
	tab depe d_def_`var'2
	}
    
	local x=2
	foreach var in leng mat cs hist {
	local letter: word `x' of `c(ALPHA)'
	display "`letter'"
	preserve
	collapse (mean) d_def_`var'2 d_def_ido_`var'2 , by(depe)
	export excel using "$Output\240227_porcent_def_media_depe_2023_v1.xlsx", sheet(EE_def_depe,modify) firstrow(var) cell("`letter'2")
	restore
	local x=`x'+5
	}		
	
	
**# Total de horas docentes que faltan por dependencia y asignatura
	foreach var in leng mat cs hist{
	tabstat def_`var'2 if d_def_`var'2==1 , by(depe) s(sum)
	tabstat def_ido_`var'2 if d_def_ido_`var'2==1 , by(depe) s(sum)
	}

	foreach var in leng mat cs hist{
	preserve	
	collapse (sum) def_`var'2 if d_def_`var'2==1 , by(depe)
	sort depe
	export excel using "$Output\240227_def_media_depe_2023_v1.xlsx", sheet(depe_`var',modify) firstrow(var) cell(B2)
	restore 

	preserve	
	collapse (sum) def_ido_`var'2 if d_def_ido_`var'2==1 , by(depe)
	sort depe
	export excel using "$Output\240227_def_media_depe_2023_v1.xlsx", sheet(depe_`var',modify) firstrow(var) cell(F2)
	restore 
	
	preserve
	collapse (sum) dda_hrs_`var' , by(depe)
	sort depe
	export excel using "$Output\240227_def_media_depe_2023_v1.xlsx", sheet(depe_`var',modify) firstrow(var) cell(K2)
	restore 		
	}	 


**# Porcentaje de EE con déficit por SLEP y asignatura
	merge m:1 rbd using "$Sostenedores\rbd_slep_2023.dta"
	drop if _merge==2
	drop _merge
	
	encode nom_sle, gen(slep)
	drop nom_sle
	
	foreach var in leng mat cs hist {
	display "Mostrando la situación para la asignatura `var'"
	tabstat d_def_`var'2 d_def_ido_`var'2 if depe==3, by(slep) s(mean) f(%9.4f)
	tab slep d_def_`var'2
	}
    
	local x=2
	foreach var in leng mat cs hist {
	local letter: word `x' of `c(ALPHA)'
	display "`letter'"
	preserve
	collapse (mean) d_def_`var'2 d_def_ido_`var'2 if depe==3, by(slep)
	export excel using "$Output\240227_porcent_def_media_slep_2023_v1.xlsx", sheet(EE_def_slep,modify) firstrow(var) cell("`letter'2")
	restore
	local x=`x'+5
	}		
	

**# Total de horas docentes que faltan por SLEP y asignatura
	foreach var in leng mat cs hist{
	tabstat def_`var'2 if d_def_`var'2==1 , by(slep) s(sum)
	tabstat def_ido_`var'2 if d_def_ido_`var'2==1 , by(slep) s(sum)
	}

	foreach var in leng mat cs hist{
	preserve	
	collapse (sum) def_`var'2 if d_def_`var'2==1 & depe==3, by(slep)
	export excel using "$Output\240227_def_media_slep_2023_v1.xlsx", sheet(slep_`var',modify) firstrow(var) cell(B2)
	restore 

	preserve	
	collapse (sum) def_ido_`var'2 if d_def_ido_`var'2==1 & depe==3, by(slep)
	export excel using "$Output\240227_def_media_slep_2023_v1.xlsx", sheet(slep_`var',modify) firstrow(var) cell(G2)
	restore 
	
	preserve	
	collapse (sum) dda_hrs_`var' if depe==3, by(slep)
	export excel using "$Output\240227_def_media_slep_2023_v1.xlsx", sheet(slep_`var',modify) firstrow(var) cell(K2)
	restore 
	}	
	
	
********************** Resultados en cantidad de docentes **********************
	
**# Se generan tramos de docentes faltantes para calcular el % de establecimientos con déficit por tramos
	foreach var in leng mat cs hist{	
	tab def_`var'2_doc if d_def_`var'2==1	    
	summarize def_`var'2_doc if d_def_`var'2==1,d 
	}
	
	
	**Distribución de establecimientos con déficit docente   
	foreach var in leng mat cs hist{	
	preserve        
	keep if d_def_`var'2==1
	gsort -def_`var'2_doc
	replace def_`var'2_doc=def_`var'2_doc*-1 if d_def_`var'2==1
	summarize def_`var'2_doc if d_def_`var'2==1,d 

    
	local p25= `r(p25)'
	local p50= `r(p50)'
	local p75= `r(p75)'
	
	histogram def_`var'2_doc if d_def_`var'2==1, width(1) discrete ///
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
	graph export "$Output\240227_distribucion_docentes_faltantes_`var'.png" , replace
	restore
	}

	
	**Variable dicotómica para cada tramo
	foreach var in leng mat cs hist{	 	    
	gen tramo1_`var'=0 if def_`var'2_doc!=.
	replace tramo1_`var'=1 if def_`var'2_doc >-3 & d_def_`var'2==1
	
	gen tramo2_`var'=0 if def_`var'2_doc!=.
	replace tramo2_`var'=1 if def_`var'2_doc <=-3 & def_`var'2_doc >-6 & d_def_`var'2==1
	
	gen tramo3_`var'=0 if def_`var'2_doc!=.
	replace tramo3_`var'=1 if def_`var'2_doc <=-6 & d_def_`var'2==1
	}

	**Porcentaje de EE con déficit por tramos y asignatura
	foreach var in leng mat cs hist{	
	tabstat tramo1_`var' tramo2_`var' tramo3_`var', s(mean) f(%9.4f)
	}

	foreach var in leng mat cs hist {
	preserve
	collapse (mean) tramo1_`var' tramo2_`var' tramo3_`var'
	export excel using "$Output\240227_porcent_def_media_tramo_2023_v1.xlsx", sheet(EE_def_tramo_`var',modify) firstrow(var) cell(B2)
	restore
	}
	
	
**# Total de docentes que faltan por región y asignatura
	foreach var in leng mat cs hist{
	tabstat def_`var'2_doc if d_def_`var'2==1 , by(cod_reg_rbd) s(sum)
	tabstat def_ido_`var'2_doc if d_def_ido_`var'2==1 , by(cod_reg_rbd) s(sum)
	}

	foreach var in leng mat cs hist{
	preserve	
	collapse (sum) def_`var'2_doc if d_def_`var'2==1 , by(cod_reg_rbd)
	export excel using "$Output\240227_def_media_reg_2023_v1.xlsx", sheet(reg_`var'_doc,modify) firstrow(var) cell(B2)
	restore 

	preserve	
	collapse (sum) def_ido_`var'2_doc if d_def_ido_`var'2==1 , by(cod_reg_rbd)
	export excel using "$Output\240227_def_media_reg_2023_v1.xlsx", sheet(reg_`var'_doc,modify) firstrow(var) cell(G2)
	restore 
	}		
	

**# Total de docentes que faltan por dependencia y asignatura
	foreach var in leng mat cs hist{
	tabstat def_`var'2_doc if d_def_`var'2==1 , by(depe) s(sum)
	tabstat def_ido_`var'2_doc if d_def_ido_`var'2==1 , by(depe) s(sum)
	}
	
	foreach var in leng mat cs hist{
	preserve	
	collapse (sum) def_`var'2_doc if d_def_`var'2==1 , by(depe)
	sort depe
	export excel using "$Output\240227_def_media_depe_2023_v1.xlsx", sheet(depe_`var'_doc,modify) firstrow(var) cell(B2)
	restore 

	preserve	
	collapse (sum) def_ido_`var'2_doc if d_def_ido_`var'2==1 , by(depe)
	sort depe
	export excel using "$Output\240227_def_media_depe_2023_v1.xlsx", sheet(depe_`var'_doc,modify) firstrow(var) cell(F2)
	restore 
	}	
	
	
**# Total de docentes que faltan por SLEP y asignatura
	foreach var in leng mat cs hist{
	tabstat def_`var'2_doc if d_def_`var'2==1 , by(slep) s(sum)
	tabstat def_ido_`var'2_doc if d_def_ido_`var'2==1 , by(slep) s(sum)
	}
	
	foreach var in leng mat cs hist{
	preserve	
	collapse (sum) def_`var'2_doc if d_def_`var'2==1 & depe==3, by(slep)
	export excel using "$Output\240227_def_media_slep_2023_v1.xlsx", sheet(slep_`var'_doc,modify) firstrow(var) cell(B2)
	restore 

	preserve	
	collapse (sum) def_ido_`var'2_doc if d_def_ido_`var'2==1 & depe==3, by(slep)
	export excel using "$Output\240227_def_media_slep_2023_v1.xlsx", sheet(slep_`var'_doc,modify) firstrow(var) cell(F2)
	restore 
	}		
	
	**Se agrega información sobre la concentración de alumnos prioritarios por rbd 
	merge m:1 rbd using "$SEP\rbd_vulnerabilidad_2023"
	drop if _merge!=3
	drop _merge	
	
	
	