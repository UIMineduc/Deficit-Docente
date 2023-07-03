******** Deficit Docente EM

clear all
**#Directorio AAP

cd "D:\OneDrive - Ministerio de Educación\2022\18 Deficit Docente\Data"

global docentes "D:\OneDrive - Ministerio de Educación\0 0 Bases de datos - MINEDUC\Docentes\Cargos Docentes"
global matricula22 "D:\OneDrive - Ministerio de Educación\0 0 Bases de datos - MINEDUC\Matricula\2022"
global directorio "D:\OneDrive - Ministerio de Educación\0 0 Bases de datos - MINEDUC\Directorios"
global output "D:\OneDrive - Ministerio de Educación\2022\18 Deficit Docente\output\v4"

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

		* Mantenemos solo titulares y no reemplazantes
		drop if inlist(id_itc,3,7,12,19,20)
		
		* Destring de variables 
		quietly destring, dpcomma replace

	*Mantenemos a quienes ejercen como docente de aula, de forma primaria y a los que hacen clases en basica/media
	*Este se considera el universo de docentes
		*keep if inlist(1,id_ifp,id_ifs)
		keep if inlist(310,cod_ens_1,cod_ens_2)


	codebook mrun rbd
	* Solo en HC y y SIN REEMPLAZOS!
	*Tenemos un total de 55.548  personas de dotacion final como observaciones unicas, el total incluyendo repetidos es 57.213
	*considerando un total de 2,677 RBD como universo
	
	****************************************************************************
	*************************** Criterios de Idoneidad *************************
/* codigo
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
	 
	 
	 tabstat tasa_*
*/
	
	
	
	********************************************************************************
	***************************** Horas por Asignatura *****************************
	
	*Generamos asignaturas
	forv i =1/2 {
	gen lenguaje`i'=1 if inlist(subsector`i',31001,31004) // lenguaje
	gen matematicas`i'=1 if inlist(subsector`i',32001,32002) // Matemática
	gen historia`i'=1 if inlist(subsector`i',33001,33002) // Historia
	gen ciencias`i'=1 if inlist(subsector`i',35001,35002,35003,35004) // Ciencias

	}

	bys rbd: gen id=_n
	
	foreach var in lenguaje matematicas ciencias historia{
	tempvar aux
	egen `aux'=rowmax(`var'1 `var2')
	bys rbd: egen d_`var'=max(`aux')
	}
	
	egen asignaturas= rownonmiss(d_lenguaje d_matematicas d_ciencias d_historia)
	
	table asignaturas if id==1

	
**# Horas totales del establecimiento*
	*Por subsector1
	preserve
	keep if inlist(subsector1,31001,31004,32001,32002,33001,33002,35001,35002,35003,35004)
	collapse (sum) horas1, by(rbd subsector1)

	
	tempfile ofta1
	save `ofta1',replace 
	restore
	
	
	*Por subsector2
	preserve
	keep if inlist(subsector2,31001,31004,32001,32002,33001,33002,35001,35002,35003,35004)
	collapse (sum) horas2, by(rbd subsector2)
	rename subsector2 subsector1

	
	tempfile ofta2
	save `ofta2',replace 
	restore
	
				
	*Hasta acá tenemos 2649 rbd
	*Agregamos la información de la cantidad de horas para cada oferta por rbd
	
	use `ofta1',clear
	append using `ofta2'
	codebook rbd
	
	

	********************************************************************************
	* Mantenemos sectores nucleares
	rename subsector1 subsector
	
	*ajustes del merge
	recode horas1 horas2 (.=0)
	

**# Horas totales y Horas Lectivas
	*Horas disponibles del RBD
	
	*horas1 + horas2
	gen hrs_aula2=horas1+horas2
	gen hrs_lect2=hrs_aula2*4*0.65
	
	
	gen asignatura=1 if inlist(subsector,31001,31004) // lenguaje
	replace asignatura=2 if inlist(subsector,32001,32002) // Matemática	
	replace asignatura=3 if inlist(subsector,35001,35002,35003,35004) // Ciencias
	replace asignatura=4 if inlist(subsector,33001,33002) // Historia
	
	label var asignatura "Asignatura"
	label define asignaturalbl 1 "Lenguaje" 2 "Matematica" 3 "Ciencias" 4 "Historia"
	label values asignatura asignaturalbl
	
	collapse (sum)  hrs_lect2 , by(rbd asignatura)
	
	rename ( hrs_lect2) ( ofta_hrs2)
	
	
	*Nota: Tenemos 2.2649  rbd
	*Generamos el cod_ense2 para hacer el match con la demanda de horas por nivel de cada RBD
	gen cod_ense2=5
	
****************************************************************************
* Sobre el total de horas recuperadas

	tempvar horas2_total
	egen `horas2_total'=total(ofta_hrs2)
	
	levelsof `horas2_total'
* horas totales 1828489 voriginal
* Horas totales 1857047.375 incluyendo todos*


	
****************************************************************************

**# Merge demanda y oferta + info administrativa

	preserve
	use "dda_hrs_rbd_nivel_2022_38sem.dta",clear
	keep if cod_ense2==5 & rural_rbd==0
	tempfile dda
	save `dda'
	restore

	merge m:1 rbd cod_ense2 using `dda', keepusing( n_cursos dda_hrs_*)
	drop if _merge==1 // 84 (89 originalmente) RBD con docentes pero sin matricula. y 150 RBD con matricula pero sin docente, ojo uqe solo consideramos urbanos
	drop if _merge==2 // 47 (150) no hacen merge
	drop _merge
	drop dda_hrs_basica
	
	*codebook 2.641 rbd
	*agregamos data administrativa
	merge m:1 rbd using "$directorio\directorio_2022", nogen keep(3) keepusing(cod_reg_rbd cod_com_rbd cod_depe2) 
	
	
**# Cálculo del deficit
		
*Deficit general  - 1+2
	local i=1
	foreach var in leng mat cs hist{
		
		gen def_`var'2=ofta_hrs2 - dda_hrs_`var' if asignatura==`i'
					replace def_`var'2=(def_`var'2)/(30*0.65)
	local i=`i'+1
	}

	**# N de EE con deficit por asignatura
	local i=1
	foreach var in leng mat cs hist{
		
	*horas 1+2
	gen d_def_`var'2=1 if def_`var'2<0 & asignatura==`i'
		replace d_def_`var'2=0 if def_`var'2>=0 & asignatura==`i'
	
	local i=`i'+1
	}

	
	**# Redondeo del deficit de docentes
	
	foreach var in leng mat cs hist{	
		
	replace def_`var'2=ceil(def_`var'2) if d_def_`var'2==0
	replace def_`var'2=floor(def_`var'2) if d_def_`var'2==1
	
	}
	

	
	**# Figuras: Distribución de las variables
*Esta sección mostraba el comportamiento de las horas1 horas2 y la suma de ambas horas finalmente terminamos usando la suma :D

	**# Graficos Minuta
	*Cambiar titulo del gráfico de forma manual

/* graficos 
	local j=1
foreach var in leng mat cs hist {
		local z: label (asignatura) `j'
	display "graficando la variable `var' con etiqueta `z' "
	twoway kdensity def_`var'2, lp(solid) lcolor("15 105 180"*0.8) lw(medthick) ///
	title("Densidad de la dif. estimada de docentes en `z'", color(black) margin(medium)) ///
	legend(label(1 "Docentes Totales") region(fcolor(none) lcolor(none))) ///
	xtitle("Diferencia docentes estimada") ///
	ytitle("Densidad") ///
	graphregion(c(white))
	*graph export "$output\230505_def_doc_`var'_2022_distr.png", replace
	local j = `j' +1
	}
	
	global listado "def_leng2  def_mat2  def_cs2  def_hist2  "
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

*/


**# base final

	*save "230530_ofta_dda_media_2022.dta",replace
	tempfile simulacion_media
	save `simulacion_media'
	
**# Base Final	
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
		display "Mostrando la situación para la asignatura `var'"
		tabstat d_def_`var'2, by(cod_reg_rbd) s(mean) f( %9.3f)
			table  cod_reg_rbd d_def_`var'2
	}
	
	tabstat d_def* , by(cod_reg_rbd) s(mean) f( %9.3f)

	
	**# % de establecimientos con déficit por región y asignatura	
local i=2
	foreach var in leng mat cs hist {
	local letter: word `i' of `c(ALPHA)'
	display "`letter'"
		preserve
	collapse (mean) d_def_`var'2 , by(cod_reg_rbd)
	export excel using "$output\230530_n_doc_media_reg_2022_v38s_all_horas.xlsx", sheet(EE_def,modify) firstrow(var) cell("`letter'2")
	restore
	local i=`i'+5
	}
	
	


**# Total de docentes que faltan por comuna,región y asignatura

	*1-NO NETEO! Comunal
	foreach var in leng mat cs hist {
	preserve	
	capture: collapse (sum) def_`var'2 (first) cod_reg_rbd if d_def_`var'2==1 , by(cod_com_rbd)
	display "exportando la asignatura `var' "
				export excel using "$output\230530_n_doc_media_reg_2022_v38s_all_horas.xlsx", sheet("media_com_`var'",modify) firstrow(var) cell(B2)
	restore 
}	
	

	
	
**# Analisis - Dependencia

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
	 table d_def_`var'2 depe 
	}
	

	**# Dependencia - Lenguaje

	**# Tablas
	*NO NETEO! Comunal
	
	foreach var in leng mat cs hist {
	preserve	
	collapse (sum) def_`var'2 (first) cod_reg_rbd if d_def_`var'2==1 , by(cod_com_rbd depe)
	sort depe cod_com_rbd
	export excel using "$output\230530_def_media_depe_38s_all_horas.xlsx", sheet("depe_`var'",modify) firstrow(var) cell(B2)
	restore 

	}
	
