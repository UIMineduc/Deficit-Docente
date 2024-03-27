* Autores: Alonso Arraño y Carla Zúñiga
* Fecha última modificación: 27-03-24
* Código: Cálculo de la dotación y déficit docente en las asignaturas de Lenguaje
* Matematicas, Ciencias e Historia en Enseñanza Básica 


* Nota: Este cálculo excluye a los establecimientos particulares pagados


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
global SLEP "D:\OneDrive - Ministerio de Educación\BBDD\SLEP"
global Output "$main/Output\2023\Nucleares\Basica"



**# 1. BBDD Cargo docente 

	use "$Docentes\docentes_2023_publica.dta" ,clear
	
	**Se une base de directorio para identificar a los establecimientos con matrícula
	merge m:1 rbd using "$Directorio\directorio_2023_edit.dta"
	drop if _merge!=3
	drop _merge
	
	**Se une base directorio SLEP para identificar cada SLEP
	merge m:1 cod_com_rbd using "$SLEP\directorio_slep_2018_2024.dta"
	drop _merge
	replace nombre_slep="" if cod_depe2!=5
	replace agno_slep=. if cod_depe2!=5
	replace cod_slep=. if cod_depe2!=5
	
	**Se filtra EE en funcionamiento
	keep if estado_estab==1 & matricula==1
	
	**Se excluyen a los establecimientos particulares pagados
	drop if cod_depe2==3
	
	**Variables de Interés 
	keep mrun rbd id_ifp id_ifs cod_ens_1 cod_ens_2 sector1 sector2 subsector1 subsector2 horas_aula horas1 horas2 tip_tit_id_1 tip_tit_id_2 nivel1 nivel2 cod_depe2 cod_reg_rbd cod_com_rbd rural_rbd esp_id_1 esp_id_2 id_itc tip_insti_id_1 tip_insti_id_2 grado*_1 grado*_2 nom_com_rbd nombre_slep agno_slep cod_slep
	order cod_reg_rbd cod_com_rbd cod_depe2 rural_rbd rbd mrun

	**Se mantienen solo RBD urbanos
	keep if rural_rbd==0
	
	**Destring de variables 
	quietly destring, dpcomma replace
	
	**Se mantienen solamente a los establecimientos que imparten Ed. Básica 
	keep if inlist(110,cod_ens_1,cod_ens_2)
	
	**Se le asigna missing value a las observaciones que reportan horas para los subsectores incluidos en el análisis, pero que corresponden a otros códigos de enseñanza (para que al momento de hacer el collapse estas horas no se incorporen a la oferta de horas)
	forv i=1/2{
	replace subsector`i'=. if !inlist(cod_ens_`i',110)
	tab cod_ens_`i' subsector`i' if !inlist(cod_ens_`i',110)	
	}
	
	**Cantidad de rbds y docentes antes de aplicar los filtros
	codebook rbd mrun
	**El codebook hasta aquí da cuenta de 4.359 establecimientos que imparten Ens. básica (incluyendo reemplazos)
	**Total de 111.057 docentes repetidos y 109.278 docentes únicos
	
	
	**Se excluyen aquellos establecimientos que no poseen info para ninguna de las asignaturas de básica
	sort rbd
	bys rbd: gen aux_basica=0
	forv i=1/2{
	bys rbd: replace aux_basica=1 if inlist(subsector`i' ,11001,11004,12001,12002,13001,13002,13003,13004,19001)
	}
	sort rbd aux_basica
	bys rbd: replace aux_basica=aux_basica[_N]

	preserve
	bys rbd: keep if _n==1
	tab aux_basica // 4.352 establecimientos tienen información para al menos una asignatura de básica
	restore
	
	**Se dejan solamente a los establecimientos con información en al menos una asignatura
	keep if aux_basica==1 // codebook indica 4.352 establecimientos
	drop aux*

	**Se filtra para mantener solo a los docentes titulares y no reemplazantes (pero sin eliminar esas observaciones para mantener a los mismos rbds que poseen info para estas asignaturas)
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
	codebook rbd mrun
	**Total de EE que imparten ed. media es de 4.352 RBD
	**Total de 109.272 docentes únicos y un total de 111.049 de docentes totales 
	
	
**# 2. Idoneidad Docente
	
    **Condiciones para considerar:
	**La primera condicion (0) son docentes que hacen clases en el nivel de básica en alguna de estas asignaturas
	**La segunda condicion (1) son docentes que hacen clases y que además tienen el título y la especialidad correspondiente
	
	**Condicion de titulación
	**Se consideran a los titulados en Básica, Parvularia y Básica, y Básica y Media para básica y sólo título en Media para media
	gen titulo_pedagogia= 1 if (inlist(tip_tit_id_1,13,15,16) & docente==1 | inlist(tip_tit_id_2,13,15,16)) & docente==1
	gen titulo_media=1 if tip_tit_id_1==14 & docente==1 | tip_tit_id_2==14 & docente==1
	
	**Condición de hacer clases de 5to a 8vo basico
	forv j=1/2{
	forv i=5/8{
	gen clases_`i'_`j'=1 if cod_ens_`j'==110 & inlist(`i',grado1_`j',grado2_`j',grado3_`j',grado4_`j', grado5_`j', grado6_`j', grado7_`j')
	}
	gen d_clases_5_8_`j'=1 if inlist(1,clases_5_`j', clases_6_`j', clases_7_`j', clases_8_`j')
	}
	drop clases_*
	
	**Variable de idoneidad
	**Explicación: Se le asigna valor 0 a todos aquellos que declaran hacer clases en alguna de las asignaturas de Ens. Basica explicadas arriba, y valor 1 a los docentes idóneos con la especialidad, que cumplen la condición de hacer clases en el nivel & tienen la pedagogia en básica
	
	global listado1 inlist(subsector1,11001,11004,12001,12002,13001,13002,13003,13004,19001) 
	global listado2 inlist(subsector2,11001,11004,12001,12002,13001,13002,13003,13004,19001) 
	
	forv i=1/2{
	gen ido_bas`i'= 0 if inlist(subsector`i',11001,11004,12001,12002,13001,13002,13003,13004,19001) & docente==1
	replace ido_bas`i'=1 if titulo_pedagogia==1  & inlist(subsector`i',11001,11004,12001,12002,13001,13002,13003,13004,19001) & docente==1
	replace ido_bas`i'=1 if titulo_media==1 & d_clases_5_8_`i'==1 & inlist(subsector`i',11001,11004,12001,12002,13001,13002,13003,13004,19001) & docente==1
	}
	
	
**# 2.1. Tasa de docentes con especialidad

	**NOTA: en este caso se ignoran los casos en los que un docente hace clases, pero no tiene la especialidad (ido_bas=0) en un subsector, y en el otro sí tiene la especialidad (ido_bas=1) y se considera solamente el mayor (en este caso que sí tiene la especialidad). Esto es posible que genere una tasa de especialidad subestimada, dado que no estoy incorporando en el universo a estos docentes que hacen clases en un subsector en el cual no tienen la especialidad. Es decir, agrupa subsector1 y subsector2 y asigna el mayor valor
	egen tasa_especialidad=rowmax(ido_bas1 ido_bas2)
	tab tasa_especialidad // proporción de Idóneos con especialidades el 76,49%
	
	
	**Tasa de docentes con especialidad por dependencia y región
	preserve
	replace cod_depe2=2 if cod_depe2==4
	tab cod_depe2 tasa_especialidad, row
	tab cod_reg_rbd tasa_especialidad, row	
	restore
	
	preserve
	replace cod_depe2=2 if cod_depe2==4
	collapse (mean) tasa_especialidad
	export excel using "$Output\240327_tasa_especialidad_basica_2023.xlsx", sheet(tot,modify) firstrow(var) cell(B2)
	restore		
	
	preserve
	replace cod_depe2=2 if cod_depe2==4
	collapse (mean) tasa_especialidad, by(cod_depe2)	
	export excel using "$Output\240327_tasa_especialidad_basica_2023.xlsx", sheet(depe,modify) firstrow(var) cell(B2)
	restore		
	
	preserve
	replace cod_depe2=2 if cod_depe2==4
	collapse (mean) tasa_especialidad, by(cod_reg_rbd)	
	export excel using "$Output\240327_tasa_especialidad_basica_2023.xlsx", sheet(region,modify) firstrow(var) cell(B2)
	restore	
	
	preserve
	collapse (mean) tasa_especialidad if cod_depe2==5, by(agno_slep nombre_slep)	
	export excel using "$Output\240327_tasa_especialidad_basica_2023.xlsx", sheet(slep,modify) firstrow(var) cell(B2)
	restore		
	
	
**# 2.2. Estadística descriptiva docentes
	
	**Cantidad de docentes que ejercen en la asignatura, ya sean habilitados o con la especialidad (0 o 1)
	codebook mrun if tasa_especialidad!=.
	
	**Distribución de los docentes por dependencia y región
	tab cod_depe2 if tasa_especialidad!=.
	tab cod_reg_rbd if tasa_especialidad!=.
	
	**Cantidad de docentes según id_ifp e id_ifs
	codebook mrun if id_ifp==1 // 103.506 docentes ifp
    codebook mrun if id_ifs==1 // 1.781 docentes ifs
	
	**Cantidad de docentes por establecimiento según función principal o secundaria
	bys rbd: egen aux_ifp=count(mrun) if id_ifp==1
	bys rbd: egen ifp=max(aux_ifp)
	bys rbd: egen aux_ifs=count(mrun) if id_ifs==1
	bys rbd: egen ifs=max(aux_ifs)
	drop aux*
	
	**Se deja solamente una observación por rbd
	preserve
	bys rbd: keep if _n==1
	keep rbd ifp ifs
    restore

	
**# 3. Oferta de horas
	
**# 3.1. Oferta de horas por RBD y asignatura (por cada subsector)
	
	**Subsector1
	**Oferta de horas docentes idóneas
	preserve
	keep if inlist(subsector1,11001,11004,12001,12002,13001,13002,13003,13004,19001)
	collapse (sum) horas1 (first) nombre_slep agno_slep cod_slep, by(rbd subsector1)	
	tempfile ofta1
	save `ofta1',replace 
	restore
	
	**Oferta de horas docentes idóneas especialistas
	preserve
	keep if inlist(subsector1,11001,11004,12001,12002,13001,13002,13003,13004,19001)
	collapse (sum) horas1 (first) nombre_slep agno_slep cod_slep if ido_bas1==1, by(rbd subsector1)
	rename horas1 hrs_ido1
	tempfile ofta1_ido
	save `ofta1_ido',replace 
	restore

	
	**Subsector2
	**Oferta de horas docentes idóneas
	preserve
	keep if inlist(subsector2,11001,11004,12001,12002,13001,13002,13003,13004,19001)
	collapse (sum) horas2 (first) nombre_slep agno_slep cod_slep, by(rbd subsector2)
	rename subsector2 subsector1
	tempfile ofta2
	save `ofta2',replace 
	restore
	
	**Oferta de horas docentes idóneas especialistas
	preserve
	keep if inlist(subsector2,11001,11004,12001,12002,13001,13002,13003,13004,19001)
	collapse (sum) horas2 (first) nombre_slep agno_slep cod_slep if ido_bas2==1, by(rbd subsector2)
	rename subsector2 subsector1
	rename horas2 hrs_ido2
	tempfile ofta2_ido
	save `ofta2_ido',replace 
	restore
	
	**Agregamos la información de la cantidad de horas para cada oferta por rbd
	use `ofta1',clear
	append using `ofta1_ido'
	append using `ofta2'
	append using `ofta2_ido'
			
	**Mantenemos sectores nucleares
	rename subsector1 subsector
	
	**Ajustes del append
	recode horas1 horas2 hrs_ido1 hrs_ido2 (.=0)
		
**# 3.2. Horas totales y horas lectivas
		
	//// SUPUESTO: Las horas aula consideran lectivas + no lectivas, por lo que
	//// se utiliza el 65% de ellas como horas lectivas cronológicas mensuales

	**Total de horas lectivas cronológicas mensuales
	gen hrs_aula2=horas1+horas2
	gen hrs_lect2=hrs_aula2*4*0.65 

	gen hrs_aula_ido2=hrs_ido1+hrs_ido2
	gen hrs_lect_ido2=hrs_aula_ido2*4*0.65 

	collapse (sum) hrs_lect2 hrs_lect_ido2 (first) nombre_slep agno_slep cod_slep, by(rbd)
	rename (hrs_lect2 hrs_lect_ido2) (ofta_hrs2 ofta_hrs_ido2)
	
	**Se agrega cod_ense de Nivel básica para hacer el match con la demanda de horas
	gen cod_ense2=2


**# 4. Merge Oferta y Demanda de EE
	preserve
	use "$Data\dda_hrs_rbd_nivel_2023_38sem.dta",clear
	keep if cod_ense2==2 & rural_rbd==0
	tempfile dda
	save `dda'
	restore

	merge 1:1 rbd cod_ense2 using `dda', keepusing(n_cursos dda_hrs_basica)
	drop if _merge==1 //10 RBD tienen cod_ense2 erróneo en base cargo docente (en matrícula no se reportan estudiantes para básica, pero se reportan horas de básica en cargo docente)
	drop if _merge==2 //16 RBD con matrícula pero sin docentes
	drop _merge
	
	**Codebook 4.342 rbd
	**Agregamos data administrativa
	merge 1:1 rbd using "$Directorio\directorio_2023", nogen keep(3) keepusing(cod_reg_rbd cod_com_rbd cod_depe2)
	
	
	
**# 5. Cálculo del Déficit
	
**# 5.1. Transformación de Horas a Docentes
	
	/// Nota: El déficit se entiende como la diferencia entre horas disponibles y
	/// horas demandadas y se deja expresado tanto en horas como en docentes
	
	* La transformación de horas a N de docentes se basa en la mediana/promedio
	* de horas aula totales de los docentes, lo que se presenta en las figuras de
	* caracterización de horas aula en el código de horas aula. Dado que un docente 
	* hace 28 horas semanales y el 65% de estas son lectivas, se divide por (28*0,65). 
	* También se realiza la transformación diferenciando por dependencia
	* (27 - PS y 29 - Municipal y SLEP).
	
    **Cálculo del déficit idóneo
	gen def_total2=ofta_hrs2-dda_hrs_basica
	gen def_total2_doc1=def_total2/(28*0.65)
	gen def_total2_doc2=def_total2/(27*0.65) if inlist(cod_depe2,2,4)
	replace def_total2_doc2=def_total2/(29*0.65) if inlist(cod_depe2,1,5)
	
	**Cálculo del déficit idóneo especialista
	gen def_ido2=ofta_hrs_ido2-dda_hrs_basica
	gen def_ido2_doc1=def_ido2/(28*0.65) 
	gen def_ido2_doc2=def_ido2/(27*0.65) if inlist(cod_depe2,2,4)
	replace def_ido2_doc2=def_ido2/(29*0.65) if inlist(cod_depe2,1,5)


**# 5.2. Establecimientos en situación de déficit
	
	**Establecimientos con déficit idóneo
	gen d_def_tot2=1 if def_total2<0
	replace d_def_tot2=0 if def_total2>=0
	
	**Establecimientos con déficit idóneo especialista
	gen d_def_ido2=1 if def_ido2<0
	replace d_def_ido2=0 if def_ido2>=0
	

**# 5.3. Redondeo del déficit según situación
		
	**Déficit idóneo
	forv i=1/2{
	replace def_total2_doc`i'=ceil(def_total2_doc`i') if d_def_tot2==0
	replace def_total2_doc`i'=floor(def_total2_doc`i') if d_def_tot2==1
	}	
	
	**Déficit idóneo especialista	
	forv i=1/2{
	replace def_ido2_doc`i'=ceil(def_ido2_doc`i') if d_def_ido2==0
	replace def_ido2_doc`i'=floor(def_ido2_doc`i') if d_def_ido2==1
	}		
	
	
	
**# 6. Gráficos finales
	
**# 6.1. Gráficos - Horas totales - DENSIDAD
	twoway kdensity def_total2  , lp(solid) lcolor("15 105 180"*0.8) lw(medthick)  || ///
	kdensity def_ido2 , lp(dash) lw(medthick) lcolor("235 60 70"*0.8) ///
	title("Densidad de la dif. estimada de horas docentes en Ens. Básica",color(black) margin(medium) ) ///
	legend(label(1 "Idóneos") label(2 "Con especialidad") region(fcolor(none) lcolor(none))) ///
	xtitle("Diferencia horas docentes estimada") ytitle("Densidad") ///
	graphregion(c(white)) xlabel(#10) ///
	xline(0,lcolor("235 60 70"*0.8))  
	graph export "$Output\240327_def_doc_basica_2023_38sem.png",replace

**# 6.2. Gráficos - Horas totales - BOXPLOT
	graph box def_total2, ///
	legend(region(fcolor(none) lcolor(none))) ///
	graphregion(c(white)) nooutsides ///
	ytitle("Diferencia") ///
	yline(0, lpattern(solid) lcolor(black*0.6))	///
	note("Nota: Se excluyen los valores externos") ///
	box(1, color("15 105 180"*0.8))
	graph export "$Output\240327_boxplot_def_basica_2023_38sem.png",replace
	*Sacamos esto por politica CEM
	*title("Distribución dif. estimada de horas docentes Ens. Básica", color(black) margin(medium)) ///
	
	
**# 6.3. Gráfico EE con Superávit
	summarize def_total2_doc1 if d_def_tot2==0,d
    summarize def_total2_doc1 if def_total2_doc1>0,d
    
	local p25= `r(p25)'
	local p50= `r(p50)'
	local p75= `r(p75)'
	
	histogram def_total2_doc1 if def_total2_doc1>0, width(1) discrete ///
	xline(`p25',lcolor("235 60 70"*0.8))  ///
	xline(`p50',lcolor("235 60 70"*0.8))  ///
	xline(`p75',lcolor("235 60 70"*0.8))  ///	
	color( "0 112 150") ///
	lcolor( "0 112 150") ///
	lwidth(thin) ///
	fin(inten60) ///
	graphregion(c(white)) ///
	xtitle("Cantidad de docentes sobrantes",margin(small)) ///
	ytitle("Densidad")
	graph export "$Output\240327_distribucion_docentes_superavit_basica.png" , replace
	
	save "$Data\240327_ofta_dda_basica_2023.dta",replace

	
**# 7. Resultados finales (horas)

	use "$Data\240327_ofta_dda_basica_2023",clear
	
	
**# 7.1. Déficit por región
	
    **Porcentaje de EE con déficit por región	
	tabstat d_def_tot2 d_def_ido2, by(cod_reg_rbd) s(mean) f(%9.4f)
	tab cod_reg_rbd d_def_tot2
	
	preserve	
	collapse (mean) d_def_tot2 d_def_ido2 , by(cod_reg_rbd)
	export excel using "$Output\240327_porcent_def_basica_reg_2023.xlsx", sheet(EE_def_region,modify) firstrow(var) cell(B2)
	restore	
	
    **Total de horas docentes que faltan por región
	tabstat def_total2 if d_def_tot2==1 , by(cod_reg_rbd) s(sum)
	tabstat def_ido2 if d_def_ido2==1 , by(cod_reg_rbd) s(sum)
	
	preserve	
	collapse (sum) def_total2 if d_def_tot2==1 , by(cod_reg_rbd)
	export excel using "$Output\240327_def_basica_reg_2023.xlsx", sheet(reg_basica,modify) firstrow(var) cell(B2)
	restore 

	preserve	
	collapse (sum) def_ido2 if d_def_ido2==1 , by(cod_reg_rbd)
	export excel using "$Output\240327_def_basica_reg_2023.xlsx", sheet(reg_basica,modify) firstrow(var) cell(G2)
	restore 
	
	preserve	
	collapse (sum) dda_hrs_basica, by(cod_reg_rbd)
	export excel using "$Output\240327_def_basica_reg_2023.xlsx", sheet(reg_basica,modify) firstrow(var) cell(K2)
	restore 	
	

**# 7.2. Déficit por dependencia

	**Porcentaje de EE con déficit por dependencia	
	**Definición de Dependencia
	gen depe=.
	replace depe=1 if cod_depe2==1
	replace depe=2 if inlist(cod_depe2,2,4)
	replace depe=3 if cod_depe2==5
	label define depe 1 "Municipal" 2 "Subvencionado" 3 "SLEP"
	label values depe depe

	tabstat d_def_tot2 d_def_ido2, by(depe) s(mean) f(%9.4f)
	tab depe d_def_tot2

	
	preserve	
	collapse (mean) d_def_tot2 d_def_ido2 , by(depe)
	export excel using "$Output\240327_porcent_def_basica_depe_2023.xlsx", sheet(EE_def_depe,modify) firstrow(var) cell(B2)
	restore		
		
	**Total de horas docentes que faltan por dependencia
	tabstat def_total2 if d_def_tot2==1 , by(depe) s(sum)
	tabstat def_ido2 if d_def_ido2==1 , by(depe) s(sum)

	preserve	
	collapse (sum) def_total2 if d_def_tot2==1 , by(depe)
	sort depe
	export excel using "$Output\240327_def_basica_depe_2023.xlsx", sheet(depe_basica,modify) firstrow(var) cell(B2)
	restore 

	preserve	
	collapse (sum) def_ido2 if d_def_ido2==1 , by(depe)
	sort depe
	export excel using "$Output\240327_def_basica_depe_2023.xlsx", sheet(depe_basica,modify) firstrow(var) cell(F2)
	restore 

	preserve	
	collapse (sum) dda_hrs_basica , by(depe)
	sort depe
	export excel using "$Output\240327_def_basica_depe_2023.xlsx", sheet(depe_basica,modify) firstrow(var) cell(K2)
	restore 	
	
	
	
**# 7.3. Déficit por SLEP
	
	**Porcentaje de EE con déficit por SLEP		
	tabstat d_def_tot2 d_def_ido2 if depe==3, by(nombre_slep) s(mean) f(%9.4f)
	tab nombre_slep d_def_tot2
	
	preserve	
	collapse (mean) d_def_tot2 d_def_ido2 if depe==3 , by(agno_slep nombre_slep)
	export excel using "$Output\240327_porcent_def_basica_slep_2023.xlsx", sheet(EE_def_slep,modify) firstrow(var) cell(B2)
	restore		
	
	**Total de horas docentes que faltan por SLEP
	tabstat def_total2 if d_def_tot2==1 , by(nombre_slep) s(sum)
	tabstat def_ido2 if d_def_ido2==1 , by(nombre_slep) s(sum)

	preserve	
	collapse (sum) def_total2 if d_def_tot2==1 & depe==3, by(agno_slep nombre_slep)
	export excel using "$Output\240327_def_basica_slep_2023.xlsx", sheet(slep_basica,modify) firstrow(var) cell(B2)
	restore 

	preserve	
	collapse (sum) def_ido2 if d_def_ido2==1 & depe==3, by(agno_slep nombre_slep)
	export excel using "$Output\240327_def_basica_slep_2023.xlsx", sheet(slep_basica,modify) firstrow(var) cell(F2)
	restore 

	preserve	
	collapse (sum) dda_hrs_basica if depe==3, by(agno_slep nombre_slep)
	export excel using "$Output\240327_def_basica_slep_2023.xlsx", sheet(slep_basica,modify) firstrow(var) cell(K2)
	restore 		
		
**# 8. Resultados finales (docentes)
	
**# 8.1. Déficit por tramos de docentes (solo docente 28 hrs)
	
	**Se generan tramos de docentes faltantes para calcular el % de establecimientos con déficit por tramos
	tab def_total2_doc1 if d_def_tot2==1
	summarize def_total2_doc1 if d_def_tot2==1,d 
	gsort -def_total2_doc1
	
	**Distribución de establecimientos con déficit docente
	preserve
	keep if d_def_tot2==1
	gsort -def_total2_doc1
	replace def_total2_doc1=def_total2_doc1*-1 if d_def_tot2==1
	summarize def_total2_doc1 if d_def_tot2==1,d 


	local p25= `r(p25)'
	local p50= `r(p50)'
	local p75= `r(p75)'
	
	histogram def_total2_doc1 if d_def_tot2==1, width(1) discrete ///
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
	xlabel(1 5 10 15 20 25 30 35 40 44)
	graph export "$Output\240327_distribucion_docentes_faltantes_basica.png" , replace
    restore
	
	**Variable dicotómica para cada tramo
	gen tramo1=0
	replace tramo1=1 if def_total2_doc1 >-3 & d_def_tot2==1
	gen tramo2=0
	replace tramo2=1 if def_total2_doc1 <=-3 & def_total2_doc1 >-6 & d_def_tot2==1
	gen tramo3=0
	replace tramo3=1 if def_total2_doc1 <=-6 & d_def_tot2==1
	
	**Porcentaje de EE con déficit por tramos	
	tabstat tramo1 tramo2 tramo3, s(mean) f(%9.4f)

	preserve
	collapse (mean) tramo1 tramo2 tramo3
	export excel using "$Output\240327_porcent_def_basica_tramo_2023.xlsx", sheet(EE_def_tramo,modify) firstrow(var) cell(B2)
	restore	
	
	
**# 8.2. Déficit por región
	
	**Total de docentes que faltan por región
	forv i=1/2{
	tabstat def_total2_doc`i' if d_def_tot2==1 , by(cod_reg_rbd) s(sum)
	tabstat def_ido2_doc`i' if d_def_ido2==1 , by(cod_reg_rbd) s(sum)
	}	
			
	forv i=1/2{	
	preserve	
	collapse (sum) def_total2_doc`i' if d_def_tot2==1 , by(cod_reg_rbd)
	export excel using "$Output\240327_def_basica_reg_2023.xlsx", sheet(reg_basica_doc`i',modify) firstrow(var) cell(B2)
	restore 
		
	preserve	
	collapse (sum) def_ido2_doc`i' if d_def_ido2==1 , by(cod_reg_rbd)
	export excel using "$Output\240327_def_basica_reg_2023.xlsx", sheet(reg_basica_doc`i',modify) firstrow(var) cell(G2)
	restore 
	}	
	

	
**# 8.3. Déficit por dependencia
	
	**Total de docentes que faltan por dependencia
	forv i=1/2{
	tabstat def_total2_doc`i' if d_def_tot2==1 , by(depe) s(sum)
	tabstat def_ido2_doc`i' if d_def_ido2==1 , by(depe) s(sum)
	}		

	forv i=1/2{		
	preserve	
	collapse (sum) def_total2_doc`i' if d_def_tot2==1 , by(depe)
	sort depe
	export excel using "$Output\240327_def_basica_depe_2023.xlsx", sheet(depe_basica_doc`i',modify) firstrow(var) cell(B2)
	restore 
	
	preserve	
	collapse (sum) def_ido2_doc`i' if d_def_ido2==1 , by(depe)
	sort depe
	export excel using "$Output\240327_def_basica_depe_2023.xlsx", sheet(depe_basica_doc`i',modify) firstrow(var) cell(F2)
	restore 
	}	
	

**# 8.4. Déficit por SLEP
	
	**Total de docentes que faltan por SLEP
	forv i=1/2{	
	tabstat def_total2_doc`i' if d_def_tot2==1 , by(nombre_slep) s(sum)
	tabstat def_ido2_doc`i' if d_def_ido2==1 , by(nombre_slep) s(sum)
	}	

	forv i=1/2{		
	preserve	
	collapse (sum) def_total2_doc`i' if d_def_tot2==1 & depe==3, by(agno_slep nombre_slep)
	export excel using "$Output\240327_def_basica_slep_2023.xlsx", sheet(slep_basica_doc`i',modify) firstrow(var) cell(B2)
	restore 

	preserve	
	collapse (sum) def_ido2_doc`i' if d_def_ido2==1 & depe==3, by(agno_slep nombre_slep)
	export excel using "$Output\240327_def_basica_slep_2023.xlsx", sheet(slep_basica_doc`i',modify) firstrow(var) cell(F2)
	restore 
	}		
	
	
	
	