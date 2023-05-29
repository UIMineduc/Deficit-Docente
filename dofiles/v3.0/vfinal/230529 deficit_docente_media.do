*** Listado de RBD que no reportan docentes en enseñanza básica

clear all
**#Directorio AAP

cd "D:\OneDrive - Ministerio de Educación\2022\18 Deficit Docente\Data"

global docentes "D:\OneDrive - Ministerio de Educación\0 0 Bases de datos - MINEDUC\Docentes\Cargos Docentes"
global matricula22 "D:\OneDrive - Ministerio de Educación\0 0 Bases de datos - MINEDUC\Matricula\2022"
global directorio "D:\OneDrive - Ministerio de Educación\0 0 Bases de datos - MINEDUC\Directorios"
global output "D:\OneDrive - Ministerio de Educación\2022\18 Deficit Docente\output\v3"
global archivos "D:\OneDrive - Ministerio de Educación\2022\18 Deficit Docente\Deficit-Docente\dofiles\v3.0\ciencias"



**#Load Data
	
	use "$docentes\docentes_2022_publica.dta" ,clear
	
	keep if estado_estab==1
	*keep if persona==1
		
	drop estado_estab persona
	keep mrun rbd id_ifp id_ifs cod_ens_1 cod_ens_2 sector1 sector2 subsector1 subsector2 horas_aula horas1 horas2 tip_tit_id_* esp_id_* nivel* cod_depe2 cod_reg_rbd cod_com_rbd rural_rbd  id_itc nom_reg_rbd
	
	order cod_reg_rbd cod_com_rbd cod_depe2 rural_rbd rbd mrun
	
	
**# Análisis
	**# Configuraciones y criterios
		* Mantenemos solo RBD urbanos
		keep if rural_rbd==0

		* Mantenemos solo docentes titulares y no reemplazantes
		drop if inlist(id_itc,3,7,12,19,20)
		
		* Destring de variables 
		quietly destring, dpcomma replace

	*Mantenemos a quienes ejercen como docente de aula, de forma primaria y a los que hacen clases en basica/media
	*Este se considera el universo de docentes
		keep if inlist(1,id_ifp,id_ifs)
		keep if inlist(310,cod_ens_1,cod_ens_2)
		*keep if inlist(sector1,310,320,330,350)
		*keep if inlist(subsector1,31001,31004,32001,32002,33001,33002,35001,35002,35003,35004)

	codebook mrun rbd
	*Tenemos un total de 53,906 docentes como unvierso final de media
	* Universo sin los reemplazos de 53.635  y 52.028 docentes unicos
	*considerando un total de 2,674 RBD como universo
	* total de 2.672 unicos rbd sin reemplazos
	
	****************************************************************************
	*************************** Criterios de Idoneidad *************************
	
**# Idoneidad Docente

	*Generamos los titulos
	* Titulado en media y especialidad de la asignatura
	gen titulo_leng=1 if (inlist(tip_tit_id_1,14,16) & inlist(esp_id_1,141,1605)) | ( inlist(tip_tit_id_2,14,16) &  inlist(esp_id_2,141,1605))
	
	gen titulo_mat=1 if (inlist(tip_tit_id_1,14,16) & inlist(esp_id_1,142,1606)) | 	( inlist(tip_tit_id_2,14,16) &  inlist(esp_id_2,142,1606))
	
	gen titulo_fisica=1 if (inlist(tip_tit_id_1,14) & inlist(esp_id_1,143)) |  (inlist(tip_tit_id_2,14) & inlist(esp_id_2,143))
	
	gen titulo_quimica=1 if (inlist(tip_tit_id_1,14) & inlist(esp_id_1,144)) |  (inlist(tip_tit_id_2,14) & inlist(esp_id_2,144))
	
	gen titulo_biologia=1 if (inlist(tip_tit_id_1,14) & inlist(esp_id_1,145,146)) |  (inlist(tip_tit_id_2,14) & inlist(esp_id_2,145,146))
	
	gen titulo_historia=1 if (tip_tit_id_1==14 & esp_id_1==148) | (tip_tit_id_2==14 & esp_id_2==148)
	

	**# Ed Media Lenguaje

	*Realiza o no clases en lenguaje
	forv i=1/2{
	 gen ido_leng`i'=0 if inlist(subsector`i',31001,31004)
	 replace ido_leng`i'=1 if titulo_leng==1 & inlist(subsector`i',31001,31004)
	}
	
	** Tasa de idoneidad en lenguaje
	gen tasa_leng=1 if inlist(1,ido_leng1,ido_leng2)
		replace tasa_leng=0 if (ido_leng1==0 & ido_leng2==0) | (ido_leng1==0 & ido_leng2==.) | (ido_leng1==. & ido_leng2==0)

	 
	**# Ed Media Matematica

	forv i=1/2{
	 gen ido_mat`i'=0 if inlist(subsector`i',32001,32002)
	 replace ido_mat`i'=1 if titulo_mat==1 & inlist(subsector`i',32001,32002)
	}
	
	gen tasa_mat=1 if inlist(1,ido_mat1,ido_mat2)
		replace tasa_mat=0 if (ido_mat1==0 & ido_mat2==0) | (ido_mat1==0 & ido_mat2==.) | (ido_mat1==. & ido_mat2==0)

	 
**# Ed Media Ciencias
		
	**#Fisica
	forv i=1/2{
	 gen ido_fisica`i'=0 if inlist(subsector`i',35003,35004)
	 replace ido_fisica`i'=1 if titulo_fisica==1 & inlist(subsector`i',35003,35004)
	}
	
	gen tasa_fisica=1 if inlist(1,ido_fisica1,ido_fisica2)
		replace tasa_fisica=0 if (ido_fisica1==0 & ido_fisica2==0) | (ido_fisica1==0 & ido_fisica2==.) | (ido_fisica1==. & ido_fisica2==0)
		
	**#Quimica
	forv i=1/2{
	 gen ido_quimica`i'=0 if inlist(subsector`i',35002,35004)
	 replace ido_quimica`i'=1 if titulo_quimica==1 & inlist(subsector`i',35002,35004)
	}
	
	gen tasa_quimica=1 if inlist(1,ido_quimica1,ido_quimica2)
		replace tasa_quimica=0 if (ido_quimica1==0 & ido_quimica2==0) | (ido_quimica1==0 & ido_quimica2==.) | (ido_quimica1==. & ido_quimica2==0)
	
	**#Biologia
	forv i=1/2{
	 gen ido_biologia`i'=0 if inlist(subsector`i',35001,35004) 
	 replace ido_biologia`i'=1 if titulo_biologia==1 & inlist(subsector`i',35001,35004)
	}

	gen tasa_bio=1 if inlist(1,ido_biologia1,ido_biologia2)
	replace tasa_bio=0 if (ido_biologia1==0 & ido_biologia2==0) | (ido_biologia1==0 & ido_biologia2==.) | (ido_biologia1==. & ido_biologia2==0)
	
	**#Ciencias General
		forv i=1/2{
	egen ido_cs`i'=rowmax(ido_fisica`i' ido_quimica`i' ido_biologia`i')
		}

	egen tasa_cs=rowmax(ido_cs1 ido_cs2)

	
	**# Ed Media Historia
		forv i=1/2{
	gen ido_hist`i'=0 if inlist(subsector`i',33001,33002)
	replace ido_hist`i'=1 if titulo_historia==1 & inlist(subsector`i',33001,33002)
		}
		
	gen tasa_hist=1 if inlist(1,ido_hist1,ido_hist2)
	replace tasa_hist=0 if (ido_hist1==0 & ido_hist2==0) | (ido_hist1==0 & ido_hist2==.) | (ido_hist1==. & ido_hist2==0)
	
	*Dummy si el docente es idoneo para su asignatura o no, lo usaremos para sumar las horas idoneos por asignatura más adelante
			forv i=1/2{
	gen doc_ido`i'=1 if inlist(1,ido_leng`i',ido_mat`i',ido_cs`i',ido_hist`i')
			}

	 foreach var of varlist  tasa_* {
	 	tab `var'
	 }
	 
	 
	 tabstat tasa_*
	 
	 
	save "prueba.dta",replace
	
**# Horas por asignatura 
	
	do "$archivos\horas_lenguaje.do"
	do "$archivos\hora_matematicas.do"
	do "$archivos\horas_historia"
	do "$archivos\horas_bio.do"
	do "$archivos\horas_quimica.do"
	do "$archivos\horas_fisica.do"
	do "$archivos\horas_otros.do"
	
	use base_lenguaje,clear
	append using base_matematicas
	append using base_historia
	append using base_quimica
	append using base_fisica
	append using base_biologia
	append using base_otros
	
	sort rbd subsector1
	
	
	**# Etiquetado de Asignaturas
	
	*Generamos Asignaturas 
	gen asignatura=1 if inlist(subsector,31001,31004) // lenguaje
	replace asignatura=2 if inlist(subsector,32001,32002) // Matemática
	replace asignatura=3 if inlist(subsector,35001,35002,35003,35004) // Ciencias
	replace asignatura=4 if inlist(subsector,33001,33002) // Historia
	label var asignatura "Asignatura"
	label define asignaturalbl 1 "Lenguaje" 2 "Matematica" 3 "Ciencias" 4 "Historia"
	label values asignatura asignaturalbl
	
	collapse (sum) horas horas_ido, by(rbd asignatura)
	
	bys rbd: gen id=_n
	bys rbd: egen n_asignaturas=max(id)
	
	tab n_asignaturas
	
	**# Transformacion a horas aula
	
	gen hrs_aula2=horas
	gen hrs_lect2=hrs_aula2*4*0.65
	
	gen hrs_aula_ido2=horas_ido
	gen hrs_lect_ido2=hrs_aula_ido2*4*0.65
	
	rename (hrs_lect2 hrs_lect_ido2) ( ofta_hrs2 ofta_hrs_ido2 )
	
	gen cod_ense2=5

*****************************************************
********************** Chequeo **********************

/*
	bys asignatura: egen aux1=total(ofta_hrs2)
	bys asignatura: egen aux2=total(ofta_hrs_ido2)
	
	
	egen total1=total(ofta_hrs2)
	egen total2=total(ofta_hrs_ido2)
	
	
		tempvar horas2_ido

	egen `horas2_ido'=total(ofta_hrs_ido2) if asignatura==3
	
	levelsof `horas2_ido'
*/

***************************************************************************
*********** Agregando la demanda de horas *********** 
	

**# Merge demanda y oferta + info administrativa

	preserve
	use "dda_hrs_rbd_nivel_2022_38sem.dta",clear
	keep if cod_ense2==5
	keep if rural_rbd==0
	tempfile dda
	save `dda'
	restore

	merge m:1 rbd cod_ense2 using `dda', keepusing( n_cursos dda_hrs_*)
	drop if _merge==1 //83 RBD con docentes pero sin matricula. y 48 RBD con matricula pero sin docente, ojo uqe solo consideramos urbanos
	drop if _merge==2 //48 no hacen merge
	drop _merge
	drop dda_hrs_basica
	
	*codebook 2.641 rbd
	*agregamos data administrativa
	merge m:1 rbd using "$directorio\directorio_2022", nogen  keepusing(cod_reg_rbd cod_com_rbd cod_depe2) keep(3)
	
	
**# Cálculo del deficit
	**# n de docentes faltantes por asignatura
		
	*Deficit general e Idoneo - 1+2
	local i=1
	foreach var in leng mat cs hist{
		gen def_`var'2=ofta_hrs2 - dda_hrs_`var' if asignatura==`i'
					replace def_`var'2=(def_`var'2)/(30*0.65)
		gen def_ido_`var'2=ofta_hrs_ido2- dda_hrs_`var' if asignatura==`i'
					replace def_ido_`var'2=(def_ido_`var'2)/(30*0.65)
	local i=`i'+1
	}

	**# N de EE con deficit por asignatura
	local i=1
	foreach var in leng mat cs hist{
	*horas 1+2
	gen d_def_`var'2=1 if def_`var'2<0 & asignatura==`i'
		replace d_def_`var'2=0 if def_`var'2>=0 & asignatura==`i'
	
	gen d_def_ido_`var'2=1 if def_ido_`var'2<0 & asignatura==`i'
		replace d_def_ido_`var'2=0 if def_ido_`var'2>=0 & asignatura==`i'
	local i=`i'+1
	}

	
	**# Redondeo del deficit de docentes
	
	foreach var in leng mat cs hist{	
	replace def_`var'2=ceil(def_`var'2) if d_def_`var'2==0
	replace def_`var'2=floor(def_`var'2) if d_def_`var'2==1
	
	
	replace def_ido_`var'2=ceil( def_ido_`var'2) if d_def_ido_`var'2==0
	replace def_ido_`var'2=floor( def_ido_`var'2) if d_def_ido_`var'2==1
	}
	
	
	**# Figuras: Distribución de las variables
*Esta sección mostraba el comportamiento de las horas1 horas2 y la suma de ambas horas finalmente terminamos usando la suma :D

/* Graficos antiguos
	foreach var in mat {
	twoway kdensity def_`var'1 || kdensity def_`var'2 || kdensity def_ido_`var'1 || kdensity def_ido_`var'2, title("Densidad del déficit docente en `var'") legend(label(1 "Deficit Total 1") label(2 "Deficit Total 1+2") label(3 "Deficit Idoneo 1") label(4 "Deficit Idoneo 1 +2"))
	graph export "$output\deficit_docente_`var'_2022_distribucion.png", replace
	}
	
	foreach var in leng mat cs hist{
	graph box def_`var'1  def_`var'2   def_ido_`var'1   def_ido_`var'2,title("Distribución del déficit docente - `var'") legend(label(1 "Deficit Total 1") label(2 "Deficit Total 1+2") label(3 "Deficit Idoneo 1") label(4 "Deficit Idoneo 1 +2"))
	graph export "$output\deficit_docente_`var'_2022_boxplot.png",replace
	}
	*/


	**# Graficos Minuta
	*Cambiar titulo del gráfico de forma manual

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
	graph export "$output\230529_def_doc_`var'_2022_distr.png", replace
	local j = `j' +1
	}
	
	/* Gráfico Antiguo
	foreach var in hist    {
	graph box def_`var'2  def_ido_`var'2, title("Densidad de la dif. estimada de docente en Historia") legend(label(1 "superávit/déficit Total") label(2 "superávit/déficit idóneo")) graphregion(c(white)) nooutsides
	*graph export "$output\230505_def_doc_`var'_2022__boxplot.png",replace
	}
	*/
	
	global listado "def_leng2 def_ido_leng2 def_mat2 def_ido_mat2 def_cs2 def_ido_cs2 def_hist2  def_ido_hist2"
	graph box def_leng2 def_ido_leng2 def_mat2 def_ido_mat2 def_cs2 def_ido_cs2 def_hist2  def_ido_hist2 , ///
	title("Distribución dif. estimada de docentes en enseñanza media", color(black) margin(l-7)) ///
	subtitle("por asignatura") ///
	legend(label(1 "Dif. Lenguaje Total") ///
	label(2 "Dif. Lenguaje Idoneo") ///
	label(3 "Dif. Matemáticas Total") ///
	label(4 "Dif. Matemáticas Idoneo") ///
	label(5 "Dif. Ciencias Total") ///
	label(6 "Dif. Ciencias Idoneo") ///
	label(7 "Dif. Historia Total") ///
	label(8 "Dif. Historia Idoneo") ///
	region(fcolor(none) lcolor(none))) ///
	graphregion(c(white)) nooutsides ///
	ytitle("Diferencia") ///
	note("Se excluyen los valores externos")
	*graph export "$output\230505_def_doc_media_2022__boxplot.png",replace
	
	graph box def_ido_leng2 def_ido_mat2 def_ido_cs2 def_ido_hist2, title("Distribución diferencia estimada de docentes en Ens. Media") ///
	subtitle("por asignatura") ///
	legend(label(1 "Dif. Lenguaje Idoneo") ///
	label(2 "Dif. Matemáticas Idoneo") ///
	label(3 "Dif. Ciencias Idoneo") ///
	label(4 "Dif. Historia Idoneo")) ///
	graphregion(c(white)) nooutsides ///
	ytitle("Diferencia")
	*graph export "$output\230505_def_doc_media_2022_boxplot_ido.png",replace

	*twoway kdensity def_*2 || kdensity def_ido_*2, title("Densidad del superávit/déficit docente en Historia")  xtitle("Diferencia docentes estimada") ytitle("Densidad") graphregion(c(white))


	save "230529_ofta_dda_media_2022.dta",replace
	tempfile simulacion_media
	save `simulacion_media'
	
**# Base Final	
	**# Exportar a excel - resultados

	*use "ofta_dda_media_2022",clear
	use `simulacion_media',clear
	

	**# % de EE con deficit, no exporta
	
*Promedio de deficit por región
	
		*Podemos generar la tabla acá
	foreach var in leng mat cs hist {
		display "Mostrando la situación para la asignatura `var'"
		tabstat d_def_`var'2 d_def_ido_`var'2, by(cod_reg_rbd) s(mean)
	}
	
	
	
	**#% de establecimientos con déficit por región y asignatura	
local i=2
	foreach var in leng mat cs hist {
	local letter: word `i' of `c(ALPHA)'
	display "`letter'"
		preserve
	collapse (mean) d_def_`var'2 d_def_ido_`var'2 , by(cod_reg_rbd)
	export excel using "$output\230529_n_doc_media_reg_2022_v38s.xlsx", sheet(EE_def,modify) firstrow(var) cell("`letter'2")
	restore
	local i=`i'+5
	}
	
	
	
******Total de docentes que faltan por comuna,región y asignatura

	*1-NO NETEO! Comunal
	foreach var in leng mat cs hist {
	preserve	
	collapse (sum) def_`var'2 (first) cod_reg_rbd if d_def_`var'2==1 , by(cod_com_rbd)
				export excel using "$output\230529_n_doc_media_reg_22_`var'_38s.xlsx", sheet(media_com,modify) firstrow(var) cell(B2)
	restore 

	preserve	
	collapse (sum) def_ido_`var'2 (first) cod_reg_rbd if d_def_ido_`var'2==1 , by(cod_com_rbd)
				export excel using "$output\230529_n_doc_media_reg_22_`var'_38s.xlsx", sheet(media_com,modify) firstrow(var) cell(F2)
	
	restore 
}	
	

	
	
**# Analisis - Dependencia

	*use "230529_ofta_dda_media_2022",clear
	
	
	*Definición de Dependencia
	*generamos la dependencia para el CEM entre público y part.sub
	gen depe=.
		replace depe=1 if cod_depe2==1
		replace depe=2 if inlist(cod_depe2,2,4)
		replace depe=3 if cod_depe2==3
		replace depe=4 if cod_depe2==5
		
	label define depe 1 "Público" 2 "Subvencionado" 3 "Particular" 4 "SLEP"
	label  values depe depe
	

	foreach var in leng mat cs hist {
	 tabstat def_ido_`var'2 if d_def_ido_`var'2 , by(depe) s(mean sd n)
	}
	
		foreach var in leng mat cs hist {
	 tabstat d_def_`var'2 d_def_ido_`var'2 , by(cod_reg_rbd) s(mean)
	}
	
	/*para exportar los resultados
	eststo X : qui estpost tabstat x1 x2 x3 x4 , by(country) stats(mean) 
esttab X using summary.csv , cells("x1 x2 x3 x4") plain nomtitle nonumber noobs 
*/

	bys rbd: gen id=_n	
	bys rbd: egen asignacion=max(id)
	
	tab asignacion if id==1
	**# Dependencia - Lenguaje

	**# Tablas
	*NO NETEO! Comunal
	
	foreach var in leng mat cs hist {
	preserve	
	collapse (sum) def_`var'2 (first) cod_reg_rbd if d_def_`var'2==1 , by(cod_com_rbd depe)
	sort depe cod_com_rbd
	export excel using "$output\230529_def_media_depe.xlsx", sheet("depe_`var'",modify) firstrow(var) cell(B2)
	restore 

	preserve	
	collapse (sum) def_ido_`var'2 (first) cod_reg_rbd if d_def_ido_`var'2==1 , by(cod_com_rbd depe)
	sort depe cod_com_rbd
	export excel using "$output\230529_def_media_depe.xlsx", sheet("depe_`var'",modify) firstrow(var) cell(F2)
	restore 
	}
	



