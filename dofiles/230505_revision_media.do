*** Listado de RBD que no reportan docentes en enseñanza básica

clear all
**#Directorio AAP

cd "D:\OneDrive - Ministerio de Educación\2022\18 Deficit Docente\Data"

global docentes "D:\OneDrive - Ministerio de Educación\0 0 Bases de datos - MINEDUC\Docentes\Cargos Docentes"
global matricula22 "D:\OneDrive - Ministerio de Educación\0 0 Bases de datos - MINEDUC\Matricula\2022"
global matricula18 "D:\OneDrive - Ministerio de Educación\0 0 Bases de datos - MINEDUC\Matricula\2018"
global directorio "D:\OneDrive - Ministerio de Educación\0 0 Bases de datos - MINEDUC\Directorios"
global output "D:\OneDrive - Ministerio de Educación\2022\18 Deficit Docente\output"


*3- Determinar cuántos docentes titulados por materia seleccionada ejercen como función principal la docencia de aula en cada rbd.

**#Load Data
	
	*import delimited "$docentes\Docentes_2022_PUBLICA.csv", varnames(1) encoding(UTF-8) clear 
	*save "$docentes\docentes_2022_publica.dta",replace
	
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
	**# Ed Media Lenguaje
	*sector1
	gen titulo_leng=1 if (inlist(tip_tit_id_1,14,16) | inlist(tip_tit_id_2,14,16)) & (inlist(esp_id_1,141,1605) | inlist(esp_id_2,141,1605))
	
	forv i=1/2{
	 gen ido_leng`i'=0 if titulo_leng!=1 & inlist(subsector`i',31001,31004)
	 replace ido_leng`i'=1 if titulo_leng==1 & inlist(subsector`i',31001,31004)
	}
	
	** Tasa de idoneidad en lenguaje
	gen tasa_leng=1 if inlist(1,ido_leng1,ido_leng2)
		replace tasa_leng=0 if (ido_leng1==0 & ido_leng2==0) | (ido_leng1==0 & ido_leng2==.) | (ido_leng1==. & ido_leng2==0)

	 
	**# Ed Media Matematica
	gen titulo_mat=1 if (inlist(tip_tit_id_1,14,16) | inlist(tip_tit_id_2,14,16)) & (inlist(esp_id_1,142,1606) | inlist(esp_id_2,142,1606))
	
	forv i=1/2{
	 gen ido_mat`i'=0 if titulo_mat!=1 & inlist(subsector`i',32001,32002)
	 replace ido_mat`i'=1 if titulo_mat==1 & inlist(subsector`i',32001,32002)
	}
	
	gen tasa_mat=1 if inlist(1,ido_mat1,ido_mat2)
		replace tasa_mat=0 if (ido_mat1==0 & ido_mat2==0) | (ido_mat1==0 & ido_mat2==.) | (ido_mat1==. & ido_mat2==0)

	 
**# Ed Media Ciencias
		
	**#Fisica
	forv i=1/2{
	 gen ido_fisica`i'=0 if (!inlist(tip_tit_id_`i',14) | !inlist(esp_id_`i',143)) & inlist(subsector`i',35003,35004)
	 replace ido_fisica`i'=1 if inlist(tip_tit_id_`i',14) & inlist(esp_id_`i',143) & inlist(subsector`i',35003,35004)
	}
	
	gen tasa_fisica=1 if inlist(1,ido_fisica1,ido_fisica2)
		replace tasa_fisica=0 if (ido_fisica1==0 & ido_fisica2==0) | (ido_fisica1==0 & ido_fisica2==.) | (ido_fisica1==. & ido_fisica2==0)

	**#Quimica
	forv i=1/2{
	 gen ido_quimica`i'=0 if (!inlist(tip_tit_id_`i',14) | !inlist(esp_id_`i',144)) & inlist(subsector`i',35002,35004)
	 replace ido_quimica`i'=1 if inlist(tip_tit_id_`i',14) & inlist(esp_id_`i',144) & inlist(subsector`i',35002,35004)
	}
	
	gen tasa_quimica=1 if inlist(1,ido_quimica1,ido_quimica2)
		replace tasa_quimica=0 if (ido_quimica1==0 & ido_quimica2==0) | (ido_quimica1==0 & ido_quimica2==.) | (ido_quimica1==. & ido_quimica2==0)
	
	**#Biologia
	forv i=1/2{
	 gen ido_biologia`i'=0 if (!inlist(tip_tit_id_`i',14) | !inlist(esp_id_`i',145,146)) & inlist(subsector`i',35001,35004) 
	 replace ido_biologia`i'=1 if inlist(tip_tit_id_`i',14) & inlist(esp_id_`i',145,146) & inlist(subsector`i',35001,35004)
	}

	gen tasa_bio=1 if inlist(1,ido_biologia1,ido_biologia2)
	replace tasa_bio=0 if (ido_biologia1==0 & ido_biologia2==0) | (ido_biologia1==0 & ido_biologia2==.) | (ido_biologia1==. & ido_biologia2==0)
	
	**#Ciencias General
		forv i=1/2{
	gen ido_cs`i'=1 if (ido_fisica`i'==1|ido_quimica`i'==1|ido_biologia`i'==1)
	replace ido_cs`i'=0 if (ido_fisica`i'==0|ido_quimica`i'==0|ido_biologia`i'==0)
		}
		
	gen tasa_cs=1 if inlist(1,ido_cs1,ido_cs2)
	replace tasa_cs=0 if (ido_cs1==0 & ido_cs2==0) | (ido_cs1==0 & ido_cs2==.) | (ido_cs1==. & ido_cs2==0)
	
	**# Ed Media Historia
		forv i=1/2{
	gen ido_hist`i'=0 if (tip_tit_id_`i'!=14 | esp_id_`i'!=148)  & inlist(subsector`i',33001,33002)
	replace ido_hist`i'=1 if tip_tit_id_`i'==14 & esp_id_`i'==148 & inlist(subsector`i',33001,33002)
		}
		
	gen tasa_hist=1 if inlist(1,ido_hist1,ido_hist2)
	replace tasa_hist=0 if (ido_hist1==0 & ido_hist2==0) | (ido_hist1==0 & ido_hist2==.) | (ido_hist1==. & ido_hist2==0)
	
	*Dummy si el docente es idoneo para su asignatura o no, lo usaremos para sumar las horas idoneos por asignatura más adelante
			forv i=1/2{
	gen doc_ido`i'=1 if inlist(1,ido_leng`i',ido_mat`i',ido_cs`i',ido_hist`i')
			}
			
	 foreach var of varlist  ido* {
	 	tab `var'
	 }
	 
	 
	 tabstat ido_*, by(cod_reg_rbd)
	 ********************************************************************************
	********************************************************************************
		
		* Horas totales del establecimiento*
	*Por subsector1
	preserve
	collapse (sum) horas1, by(rbd sector1 subsector1)
	keep if inlist(subsector1,31001,31004,32001,32002,33001,33002,35001,35002,35003,35004)
	tempfile ofta1
	save `ofta1',replace 
	restore
	
	preserve
	collapse (sum) horas1 if doc_ido1==1, by(rbd sector1 subsector1)
	keep if inlist(subsector1,31001,31004,32001,32002,33001,33002,35001,35002,35003,35004)
	rename horas1 hrs_ido1
	tempfile ofta1_ido
	save `ofta1_ido',replace 
	restore
	
	*Por subsector2
	preserve
	collapse (sum) horas2, by(rbd sector2 subsector2)
	rename sector2 sector1
	rename subsector2 subsector1
	keep if inlist(subsector1,31001,31004,32001,32002,33001,33002,35001,35002,35003,35004)
	tempfile ofta2
	save `ofta2',replace 
	restore
	
	preserve
	collapse (sum) horas2 if doc_ido2==1, by(rbd sector2 subsector2)
	rename sector2 sector1
	rename subsector2 subsector1
	rename horas2 hrs_ido2
	keep if inlist(subsector1,31001,31004,32001,32002,33001,33002,35001,35002,35003,35004)
	tempfile ofta2_ido
	save `ofta2_ido',replace 
	restore
		
	*agregamos la cantidad de docentes según id_ifp e id_ifs
	bys rbd: egen aux_ifp=count(mrun) if id_ifp==1
		bys rbd: egen ifp=max(aux_ifp)
	bys rbd: egen aux_ifs=count(mrun) if id_ifs==1
		bys rbd: egen ifs=max(aux_ifs)
	drop aux*
	
	bys rbd: keep if _n==1
	keep rbd ifp ifs		
		
	*Hasta acá tenemos n rbd
	*Agregamos la información de la cantidad de horas para cada oferta por rbd
	
	merge 1:m rbd using `ofta1'
	drop _merge
	codebook rbd

	merge 1:1 rbd sector1 subsector1 using `ofta1_ido'
	drop _merge
	codebook rbd
	
	merge 1:1 rbd sector1 subsector1 using `ofta2'
	drop _merge
	codebook rbd
	
	merge 1:1 rbd sector1 subsector1 using `ofta2_ido'
	drop _merge
	codebook rbd

	********************************************************************************
	* Mantenemos sectores nucleares
	rename sector1 sector
	rename subsector1 subsector
	
	*ajustes del merge
	recode horas1 horas2 hrs_ido1 hrs_ido2(.=0)
	
	bys rbd: egen doc_ifp=max(ifp)
	bys rbd: egen doc_ifs=max(ifs)
	
	drop ifp ifs

	*Horas disponibles del RBD
	*solo horas1
	gen hrs_aula1=horas1
	gen hrs_lect1=hrs_aula1*4*0.65
	
	gen hrs_aula_ido1=hrs_ido1
	gen hrs_lect_ido1=hrs_aula_ido1*4*0.65
	
	*horas1 + horas2
	gen hrs_aula2=horas1+horas2
	gen hrs_lect2=hrs_aula2*4*0.65
	
	gen hrs_aula_ido2=hrs_ido1+hrs_ido2
	gen hrs_lect_ido2=hrs_aula_ido2*4*0.65
	
	*Generamos Asignaturas 
	gen asignatura=1 if inlist(subsector,31001,31004) // lenguaje
		replace asignatura=2 if inlist(subsector,32001,32002) // Matemática
		replace asignatura=3 if inlist(subsector,35001,35002,35003,35004) // Ciencias
		replace asignatura=4 if inlist(subsector,33001,33002) // Historia
	label var asignatura "Asignatura"
	label define asignaturalbl 1 "Lenguaje" 2 "Matematica" 3 "Ciencias" 4 "Historia"
	label values asignatura asignaturalbl
	
	collapse (sum) hrs_lect1 hrs_lect_ido1 hrs_lect2 hrs_lect_ido2 (first) doc_ifp doc_ifs, by(rbd asignatura)
	
	rename (hrs_lect1 hrs_lect2) (ofta_hrs1 ofta_hrs2)
	rename (hrs_lect_ido1 hrs_lect_ido2) (ofta_hrs_ido1 ofta_hrs_ido2)
	
	
	*Nota: Tenemos 2.672  rbd
	*Generamos el cod_ense2 para hacer el match con la demanda de horas por nivel de cada RBD
	gen cod_ense2=5

	

**# Merge demanda y oferta + info administrativa

	preserve
	use "dda_hrs_rbd_nivel_2022.dta",clear
	keep if cod_ense2==5
	tempfile dda
	save `dda'
	restore

	merge m:1 rbd cod_ense2 using `dda', keepusing( n_cursos dda_hrs_*)
	drop if _merge==1 //89 RBD con docentes pero sin matricula. y 149 RBD con matricula pero sin docente, ojo uqe solo consideramos urbanos
	drop if _merge==2 //150 no hacen merge
	drop _merge
	drop dda_hrs_basica
	
	*codebook 2.641 rbd
	*agregamos data administrativa
	merge m:1 rbd using "$directorio\directorio_2022", nogen keep(3) keepusing(cod_reg_rbd cod_com_rbd cod_depe2) 
	

	

**# Cálculo del deficit
	

	
	*Deficit general e Idoneo - solo 1
	local i=1
	foreach var in leng mat cs hist{
		gen def_`var'1=ofta_hrs1 - dda_hrs_`var' if asignatura==`i'
			replace def_`var'1=def_`var'1/(30*0.65)
		gen def_ido_`var'1=ofta_hrs_ido1 - dda_hrs_`var' if asignatura==`i'
			replace def_ido_`var'1=def_ido_`var'1/(30*0.65)
	local i=`i'+1
	}

	
	*Deficit general e Idoneo - 1+2
	local i=1
	foreach var in leng mat cs hist{
		gen def_`var'2=ofta_hrs2 - dda_hrs_`var' if asignatura==`i'
					replace def_`var'2=(def_`var'2)/(30*0.65)
		gen def_ido_`var'2=ofta_hrs_ido2- dda_hrs_`var' if asignatura==`i'
					replace def_ido_`var'2=(def_ido_`var'2)/(30*0.65)
	local i=`i'+1
	}

		drop if asignatura==.
	
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


* Graficos Minuta
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
	graph export "$output\230505_def_doc_`var'_2022_distr.png", replace
	local j = `j' +1
	}
	
	/* Gráfico Antiguo
	foreach var in hist    {
	graph box def_`var'2  def_ido_`var'2, title("Densidad de la dif. estimada de docente en Historia") legend(label(1 "superávit/déficit Total") label(2 "superávit/déficit idóneo")) graphregion(c(white)) nooutsides
	graph export "$output\230505_def_doc_`var'_2022__boxplot.png",replace
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
	graph export "$output\230505_def_doc_media_2022__boxplot.png",replace
	
	graph box def_ido_leng2 def_ido_mat2 def_ido_cs2 def_ido_hist2, title("Distribución diferencia estimada de docentes en Ens. Media") ///
	subtitle("por asignatura") ///
	legend(label(1 "Dif. Lenguaje Idoneo") ///
	label(2 "Dif. Matemáticas Idoneo") ///
	label(3 "Dif. Ciencias Idoneo") ///
	label(4 "Dif. Historia Idoneo")) ///
	graphregion(c(white)) nooutsides ///
	ytitle("Diferencia")
	graph export "$output\230505_def_doc_media_2022_boxplot_ido.png",replace

	*twoway kdensity def_*2 || kdensity def_ido_*2, title("Densidad del superávit/déficit docente en Historia")  xtitle("Diferencia docentes estimada") ytitle("Densidad") graphregion(c(white))



	local i=1
	foreach var in leng mat cs hist{
	*horas 1
	gen d_def_`var'1=1 if def_`var'1<0 & asignatura==`i'
		replace d_def_`var'1=0 if def_`var'1>=0 & asignatura==`i'
	
	gen d_def_ido_`var'1=1 if def_ido_`var'1<0 & asignatura==`i'
		replace d_def_ido_`var'1=0 if def_ido_`var'1>=0 & asignatura==`i'
		
	*horas 1+2
	gen d_def_`var'2=1 if def_`var'2<0 & asignatura==`i'
		replace d_def_`var'2=0 if def_`var'2>=0 & asignatura==`i'
	
	gen d_def_ido_`var'2=1 if def_ido_`var'2<0 & asignatura==`i'
		replace d_def_ido_`var'2=0 if def_ido_`var'2>=0 & asignatura==`i'
	local i=`i'+1
	}

	*save "ofta_dda_media_2022.dta",replace
	tempfile simulacion_media
	save `simulacion_media'
	
	
**# Exportar a excel - resultados

	*use "ofta_dda_media_2022",clear
	use `simulacion_media',clear
	
/* REVISAR ESTA SECCION DEL CODIGO
*suma de docentes faltantes
	forv i=1(1)4{
		preserve
			collapse (sum) def if asignatura==`i', by(cod_reg_rbd)
		restore
	}
	
	collapse (mean) d_def*, by(cod_reg_rbd)

	
*suma de docentes idoneos faltantes
	use "ofta_dda_media_2022",clear

	
		forv i=1(1)4{
			preserve
				keep if asignatura==`i'
				collapse (sum) def_*, by(cod_reg_rbd)
				export excel using "$output\230123_n_def_doc_media_reg_2022", sheet(`i',modify) firstrow(var)
			restore
		}
	*/		
		
*Promedio de deficit por región
	*use "ofta_dda_media_2022",clear
	
		*Podemos generar la tabla acá
	foreach var in leng mat cs hist {
		tabstat d_def_`var'2 d_def_ido_`var'2, by(cod_reg_rbd) s(mean)
	}
	
	tabstat $listado , by(cod_reg_rbd) s(mean) f( %9.2f)
	
*% de establecimientos con déficit por región y asignatura	
local i=2
	foreach var in leng mat cs hist {
	local letter: word `i' of `c(ALPHA)'
	display "`letter'"
		preserve
	collapse (mean) d_def_`var'2 d_def_ido_`var'2 , by(cod_reg_rbd)
	export excel using "$output\230505_n_def_doc_reg_2022_v2", sheet(media_ee,modify) firstrow(var) cell("`letter'2")
	restore
	local i=`i'+5
	}
	
	

**# Total de docentes que faltan por región y asignatura
/* CODIGO ANTIGUO 
	*1-NO NETEO! Regional
	foreach var in leng mat cs hist {
	preserve	
	
	collapse (sum) def_`var'2  if d_def_`var'2==1 , by(cod_reg_rbd)
	export excel using "$output\230505_n_doc_media_reg_22_`var'", sheet(media,modify) firstrow(var) cell(A2)
	restore 

	preserve	
	
	collapse (sum) def_ido_`var'2 if d_def_ido_`var'2==1 , by(cod_reg_rbd)
	export excel using "$output\230505_n_doc_media_reg_22_`var'", sheet(media,modify) firstrow(var) cell(E2)
				
	restore 
	
	*2 - Neteo Regional
	preserve
	
	collapse (sum) def_`var'2  , by(cod_reg_rbd)
	export excel using "$output\230505_n_doc_media_reg_22_`var'", sheet(media_neto,modify) firstrow(var) cell(A2)
				
	restore 

	preserve	
	collapse (sum) def_ido_`var'2  , by(cod_reg_rbd)
				export excel using "$output\230505_n_doc_media_reg_22_`var'", sheet(media_neto,modify) firstrow(var) cell(E2)
	restore 
	*/

******Total de docentes que faltan por comuna,región y asignatura

	*1-NO NETEO! Comunal
	foreach var in leng mat cs hist {
	preserve	
	collapse (sum) def_`var'2 (first) cod_reg_rbd if d_def_`var'2==1 , by(cod_com_rbd)
				export excel using "$output\230505_n_doc_media_reg_22_`var'", sheet(media_com,modify) firstrow(var) cell(B2)
	restore 

	preserve	
	collapse (sum) def_ido_`var'2 (first) cod_reg_rbd if d_def_ido_`var'2==1 , by(cod_com_rbd)
				export excel using "$output\230505_n_doc_media_reg_22_`var'", sheet(media_com,modify) firstrow(var) cell(E2)
	
	restore 
}	
	
	
	*2 - Neteo Comunal
/* CODIGO ANTIGUO

		preserve	
	collapse (sum) def_`var'2 (first) cod_reg_rbd , by(cod_com_rbd)
				export excel using "$output\230505_n_doc_media_reg_22_`var'", sheet(media_neto_com,modify) firstrow(var) cell(B2)
	restore 

	preserve	
	collapse (sum) def_ido_`var'2 (first) cod_reg_rbd  , by(cod_com_rbd)
				export excel using "$output\230505_n_doc_media_reg_22_`var'", sheet(media_neto_com,modify) firstrow(var) cell(E2)
	restore 
	}	
	*/
	
	
	
	
**# Analisis - Dependencia
{
	use "ofta_dda_media_2022",clear
	
	
	*generamos la dependencia para el CEM entre público y part.sub
	gen depe=.
		replace depe=1 if inlist(cod_depe2,1,5)
		replace depe=2 if inlist(cod_depe2,2,4)
		replace depe=3 if cod_depe2==3
		
	label define depe 1 "Público" 2 "Subvencionado" 3 "Particular"
	label  values depe depe
		

	foreach var in leng mat cs hist {
	 tabstat def_ido_`var'2 if d_def_ido_`var'2 , by(depe) s(mean sd n)
	}
	
	**# Dependencia - Lenguaje

	frame create lenguaje
	frame change lenguaje

	use "ofta_dda_media_2022",clear
	
	foreach var in leng mat cs hist {
	 tabstat def_ido_`var'2 if d_def_ido_`var'2 , by(depe) s(mean sd n)
	}
	
	*****Total de docentes que faltan por región y asignatura
	*1-NO NETEO! Regional
	
	local j=2
	foreach var in leng mat cs hist {
	
	preserve	
	
	collapse (sum) def_`var'2  if d_def_`var'2==1 , by(depe)
	export excel using "$output\230505_dependencia2", sheet(media,modify) firstrow(var) cell(A`j')
	restore 

	
	preserve	
	
	collapse (sum) def_ido_`var'2 if d_def_ido_`var'2==1  , by(depe)
	export excel using "$output\230505_dependencia2", sheet(media,modify) firstrow(var) cell(C`j')
				
	restore 
	
	*2 - Neteo Regional
	preserve
	
	collapse (sum) def_`var'2 , by(depe)
	export excel using "$output\230505_dependencia2", sheet(media_neto,modify) firstrow(var) cell(F`j')
				
	restore 
	

	preserve	
	collapse (sum) def_ido_`var'2  , by(depe)
				export excel using "$output\230505_dependencia2", sheet(media_neto,modify) firstrow(var) cell(H`j')
	restore 
		

******Total de docentes que faltan por comuna,región y asignatura

	*1-NO NETEO! Comunal
	preserve	
	collapse (sum) def_`var'2 (first) cod_reg_rbd if d_def_`var'2==1  , by(depe)
				export excel using "$output\230505_dependencia2", sheet(media_com,modify) firstrow(var) cell(L`j')
	restore 

	preserve	
	collapse (sum) def_ido_`var'2 (first) cod_reg_rbd if d_def_ido_`var'2==1, by(depe)
				export excel using "$output\230505_dependencia2", sheet(media_com,modify) firstrow(var) cell(O`j')
	restore 

	*2 - Neteo Comunal
		preserve	
	collapse (sum) def_`var'2 (first) cod_reg_rbd  , by(depe)
				export excel using "$output\230505_dependencia2", sheet(media_neto_com,modify) firstrow(var) cell(R`j')
	restore 
	
	preserve	
	collapse (sum) def_ido_`var'2 (first) cod_reg_rbd  , by(depe)
				export excel using "$output\230505_dependencia2", sheet(media_neto_com,modify) firstrow(var) cell(U`j')
	restore 
		local j=`j'+5
	}	
	
}	
	

	