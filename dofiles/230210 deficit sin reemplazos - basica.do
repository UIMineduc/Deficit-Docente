*** Listado de RBD que no reportan docentes en enseñanza básica

clear all
*Directorio AAP

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
	keep mrun rbd id_ifp id_ifs cod_ens_1 cod_ens_2 sector1 sector2 subsector1 subsector2 horas_aula horas1 horas2 tip_tit_id_1 nivel1 nivel2 cod_depe2 cod_reg_rbd cod_com_rbd rural_rbd  esp_id_1 id_itc
	
	
**# Análisis
		* Mantenemos solo RBD urbanos
		keep if rural_rbd==0
		
		* Destring de variables 
		quietly destring, dpcomma replace

	*Mantenemos a quienes ejercen como docente de aula, de forma primaria y a los que hacen clases en basica/media
	*Este se considera el universo de docentes
		keep if inlist(1,id_ifp,id_ifs)
		keep if inlist(110,cod_ens_1,cod_ens_2)
		
		/* Listado de sectores y subsectores que son considerados, este codigo no se usa
		*keep if inlist(sector1,110,120,130,190) | inlist(sector2,110,120,130,190)
		*keep if inlist(subsector1,11001,11004,12001,12002,13001,13002,13003,13004,19001) | inlist(subsector2,11001,11004,12001,12002,13001,13002,13003,13004,19001)
		*/
	
	frame copy default analisis
	frame change analisis
	*Eliminamos a los docentes reemplazo
	drop if inlist(id_itc,3,12,20,7,19)
	

	codebook mrun rbd
	*Tenemos un total de 112,225 docentes unicos como universo final de basica usando ifp + ifs (114.483)
	*considerando un total de 4,873 RBD como universo usando ifp + ifs (Se mantiene la cantidad de RBDS)
	
	****************************************************************************
	*************************** Criterios de Idoneidad *************************
	
	*** Idoneidad Docente
	* Ed basica
	gen ido_bas=0 if inlist(2,nivel1,nivel2) & inlist(subsector1,11001,11004,12001,12002,13001,13002,13003,13004,19001)
	 replace ido_bas=1 if tip_tit_id_1==13 & inlist(2,nivel1,nivel2) & inlist(subsector1,11001,11004,12001,12002,13001,13002,13003,13004,19001)

	 tab ido_bas
	 /* Resultados:
	 proporción de idoneos es el 50% dentro de los reemplazantes
	 proporción de idóneos es del 64% sin considerar a los reemplazantes
	 */

	********************************************************************************
	* Horas totales del establecimiento*
	*Por subsector1
	preserve
	collapse (sum) horas1, by(rbd sector1 subsector1)
		keep if inlist(subsector1,11001,11004,12001,12002,13001,13002,13003,13004,19001)
	tempfile ofta1
	save `ofta1',replace 
	restore
	
	preserve
	collapse (sum) horas1 if ido_bas==1, by(rbd sector1 subsector1)
		keep if inlist(subsector1,11001,11004,12001,12002,13001,13002,13003,13004,19001)
	rename horas1 hrs_ido1
	tempfile ofta1_ido
	save `ofta1_ido',replace 
	restore
	
	*Por subsector2
	preserve
	collapse (sum) horas2, by(rbd sector2 subsector2)
	rename sector2 sector1
	rename subsector2 subsector1
		keep if inlist(subsector1,11001,11004,12001,12002,13001,13002,13003,13004,19001)
	tempfile ofta2
	save `ofta2',replace 
	restore
	
	preserve
	collapse (sum) horas2 if ido_bas==1, by(rbd sector2 subsector2)
	rename sector2 sector1
	rename subsector2 subsector1
	rename horas2 hrs_ido2
		keep if inlist(subsector1,11001,11004,12001,12002,13001,13002,13003,13004,19001)
	tempfile ofta2_ido
	save `ofta2_ido',replace 
	restore
	
	*agregamos la cantidad de docentes según id_ifp e id_ifs
	*1 - 119,122 docentes ifp
	*2 - 3,640 docentes ifs
	
	bys rbd: egen aux_ifp=count(mrun) if id_ifp==1
	bys rbd: egen ifp=max(aux_ifp)
	bys rbd: egen aux_ifs=count(mrun) if id_ifs==1
	bys rbd: egen ifs=max(aux_ifs)
	drop aux*
	
	bys rbd: keep if _n==1
	keep rbd ifp ifs

	*hasta acá tenemos 4,873 rbd
	
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
	
	*tenemos 7892 rbd con los sectores núcleares en básica. El dato anterior considera otras áreas fuera de NB.
	
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
	
	collapse (sum) hrs_lect1 hrs_lect_ido1 hrs_lect2 hrs_lect_ido2 (first) doc_ifp doc_ifs, by(rbd)
	
	rename (hrs_lect1 hrs_lect2) (ofta_hrs1 ofta_hrs2)
	rename (hrs_lect_ido1 hrs_lect_ido2) (ofta_hrs_ido1 ofta_hrs_ido2)
	
	
	*Nota: Tenemos 4,881 rbd

	*drop sector subsector horas1 horas2 hrs_*
	
	gen cod_ense2=2

****************************************************************************


**# Listado de RBDs

	preserve
	use "dda_hrs_rbd_nivel_2022.dta",clear
	keep if cod_ense2==2
	tempfile dda
	save `dda'
	restore

	/* solo para region
	preserve
	use "dda_hrs_reg_bas_2018.dta",clear
	keep if cod_ense2==2
	tempfile dda_reg
	save `dda_reg'
	restore
	*/

	merge 1:1 rbd cod_ense2 using `dda', keepusing( n_cursos dda_hrs_basica)
	drop if _merge==1 //53 RBD con docentes pero sin matricula. 
	drop _merge
	
	*solo 1
	gen def_total1=ofta_hrs1-dda_hrs_basica
	replace def_total1=def_total1/(30*0.65)
	gen def_ido1=ofta_hrs_ido1-dda_hrs_basica
		replace def_ido1=def_ido1/(30*0.65)
		
	*1 + 2
	gen def_total2=ofta_hrs2-dda_hrs_basica
	replace def_total2=def_total2/(30*0.65)
	gen def_ido2=ofta_hrs_ido2-dda_hrs_basica
		replace def_ido2=def_ido2/(30*0.65)

	*save "ofta_dda_basica_2022",replace
	tempfile simulacion
	save `simulacion'
	
	
**# Base Final

	*use "ofta_dda_basica_2022",clear
	use `simulacion',clear
	
	/* Gráficos considerando horas1 y horas 1+2
	twoway kdensity def_total1 || kdensity def_total2 || kdensity def_ido1 || kdensity def_ido2, title("Densidad del déficit docente") legend(label(1 "Deficit Total 1") label(2 "Deficit Total 1+2") label(3 "Deficit Idoneo 1") label(4 "Deficit Idoneo 1 +2"))
	graph export "$output\221129_distr_def_basica_2022.png",replace
	
	graph box def_total1  def_total2   def_ido1   def_ido2,title("Distribución del déficit docente") legend(label(1 "Deficit Total 1") label(2 "Deficit Total 1+2") label(3 "Deficit Idoneo 1") label(4 "Deficit Idoneo 1 +2"))
	graph export "$output\221129_boxplot_def_basica_2022.png",replace
	*/
	**# Graficos
	twoway kdensity def_total2 || kdensity def_ido2, title("Densidad dif. estimada de docentes en Ens. Básica") legend(label(1 "Docentes Totales") label(2 "Docentes Idoneo")) xtitle("Diferencia docentes estimada") ytitle("Densidad") graphregion(c(white))
	*graph export "$output\230209_def_basica_2022.png",replace
	
	graph box def_total2 def_ido2,title("Distribución dif. estimada de docentes Educación Básica") legend(label(1 "Docentes Total") label(2 "Docentes Idoneo")) graphregion(c(white)) nooutsides ytitle("Diferencia")
	*graph export "$output\230209_boxplot_def_basica_2022.png",replace
	
	
	
	*agregamos data administrativa
	merge 1:1 rbd using "$directorio\directorio_2022", nogen keep(3) keepusing(cod_reg_rbd cod_com_rbd cod_depe2)

	**# Tablas finales
	*Indicador por region y comuna
	bys cod_com_rbd: gen id_com=_n==1
	bys cod_reg_rbd: gen id_reg=_n==1
	
	*horas 1
	gen d_def_tot1=1 if def_total1<0
		replace d_def_tot1=0 if def_total1>=0
	
	gen d_def_ido1=1 if def_ido1<0
		replace d_def_ido1=0 if def_ido1>=0
		
	*horas 1+2
	gen d_def_tot2=1 if def_total2<0
		replace d_def_tot2=0 if def_total2>=0
	
	gen d_def_ido2=1 if def_ido2<0
		replace d_def_ido2=0 if def_ido2>=0
		
	*% de EE con déficit por región
	
	*save "ofta_dda_basica_2022.dta",replace
	
	
	*tabstat d_def_tot1 d_def_ido1 d_def_tot2 d_def_ido2, by(cod_reg_rbd)
	tabstat d_def_tot2 d_def_ido2, by(cod_reg_rbd) s(mean)

******Total de docentes que faltan por región
/* DESCRIPCION TABLAS

Basica_neto: Se debe obtener el total de cada fila, estos valores corresponden al supuesto de Considerando reasignación docente dentro de la región	

Basica_como basica: Se debe considerar la suma de todos los valores dentro de la región, dado que existe Sin considerar reasignación dentro de la región	


Basica_neto_com: Se debe generar una dummy si el valor es negativo o no, asi luego se sumaran todos los valores negativos para cada región, Considerando reasignación docente dentro de la comuna de la región	
*/

	**# Tablas - Region - Excel
	*1-NO NETEO! Regional
	preserve	
	collapse (sum) def_total2 if d_def_tot2==1 , by(cod_reg_rbd)
	insobs 1
	replace cod_reg_rbd=0 if cod_reg_rbd==.
	tempvar aux
	egen `aux'=total(def_total2)
	replace def_total2=`aux' if cod_reg_rbd==0
				export excel using "$output\230209_sim_bas_noreemplazo", sheet(basica,modify) firstrow(var) cell(B2)
	restore 

	preserve	
	collapse (sum) def_ido2 if d_def_ido2==1 , by(cod_reg_rbd)
	insobs 1
	replace cod_reg_rbd=0 if cod_reg_rbd==.
	tempvar aux
	egen `aux'=total(def_ido2)
	replace def_ido2=`aux' if cod_reg_rbd==0
				export excel using "$output\230209_sim_bas_noreemplazo", sheet(basica,modify) firstrow(var) cell(E2)
	restore 
	
	*2 - Neteo Regional
		preserve	
	collapse (sum) def_total2  , by(cod_reg_rbd)
	insobs 1
	replace cod_reg_rbd=0 if cod_reg_rbd==.
	gen dummy=1 if def_total2<0
	tempvar aux
	egen `aux'=total(def_total2) if dummy==1
	replace def_total2=`aux' if cod_reg_rbd==0
				export excel using "$output\230209_sim_bas_noreemplazo", sheet(basica_neto,modify) firstrow(var) cell(B2)
	restore 

	preserve	
	collapse (sum) def_ido2  , by(cod_reg_rbd)
	insobs 1
	replace cod_reg_rbd=0 if cod_reg_rbd==.
	gen dummy=1 if def_ido2<0
	tempvar aux
	egen `aux'=total(def_ido2) if dummy==1
	replace def_ido2=`aux' if cod_reg_rbd==0
				export excel using "$output\230209_sim_bas_noreemplazo", sheet(basica_neto,modify) firstrow(var) cell(E2)
	restore 
	

	**# Tablas - Comuna
******Total de docentes que faltan por comuna
	*1-NO NETEO! Comunal
	preserve	
	collapse (sum) def_total2 (first) cod_reg_rbd if d_def_tot2==1 , by(cod_com_rbd)
				export excel using "$output\230209_sim_bas_noreemplazo", sheet(basica_com,modify) firstrow(var) cell(B2)
	restore 

	preserve	
	collapse (sum) def_ido2 (first) cod_reg_rbd if d_def_ido2==1 , by(cod_com_rbd)
				export excel using "$output\230209_sim_bas_noreemplazo", sheet(basica_com,modify) firstrow(var) cell(F2)
	restore 
	
	*2 - Neteo Comunal
		preserve	
	collapse (sum) def_total2 (first) cod_reg_rbd , by(cod_com_rbd)
	gen def=1 if def_total2<0
				export excel using "$output\230209_sim_bas_noreemplazo", sheet(basica_neto_com,modify) firstrow(var) cell(B2)
	restore 

	preserve	
	collapse (sum) def_ido2 (first) cod_reg_rbd  , by(cod_com_rbd)
		gen def=1 if def_ido2<0
				export excel using "$output\230209_sim_bas_noreemplazo", sheet(basica_neto_com,modify) firstrow(var) cell(G2)
	restore 

**# Analisis por Dependencia
	
	use ofta_dda_basica_2022.dta,clear
	*Definición de Dependencia
	*generamos la dependencia para el CEM entre público y part.sub
	gen depe=.
		replace depe=1 if inlist(cod_depe2,1,5)
		replace depe=2 if inlist(cod_depe2,2,4)
		replace depe=3 if cod_depe2==3
		
	label define depe 1 "Público" 2 "Subvencionado" 3 "Particular"
	label  values depe depe
	
	
	**# Tablas
		*1-NO NETEO! Regional
	
	preserve	
	collapse (sum) def_total2 if d_def_tot2==1 , by(cod_reg_rbd depe) 
	sort depe cod_reg
				export excel using "$output\230208_dependencia_basica", sheet(basica,modify) firstrow(var) cell(B2)
	restore 

	preserve	
	collapse (sum) def_ido2 if d_def_ido2==1 , by(cod_reg_rbd depe)
	sort depe cod_reg
				export excel using "$output\230208_dependencia_basica", sheet(basica,modify) firstrow(var) cell(F2)
	restore 
	
	*2 - Neteo Regional
		preserve	
	collapse (sum) def_total2  , by(cod_reg_rbd depe)
	sort depe cod_reg
				export excel using "$output\230208_dependencia_basica", sheet(basica_neto,modify) firstrow(var) cell(B2)
	restore 

	preserve	
	collapse (sum) def_ido2  , by(cod_reg_rbd depe)
		sort depe cod_reg
				export excel using "$output\230208_dependencia_basica", sheet(basica_neto,modify) firstrow(var) cell(F2)
	restore
	
	*3-NO NETEO! Comunal
	preserve	
	collapse (sum) def_total2 (first) cod_reg_rbd if d_def_tot2==1 , by(cod_com_rbd depe)
	sort depe cod_com_rbd
	export excel using "$output\230208_dependencia_basica", sheet(basica_com,modify) firstrow(var) cell(B2)
	restore 

	preserve	
	collapse (sum) def_ido2 (first) cod_reg_rbd if d_def_ido2==1 , by(cod_com_rbd depe)
	sort depe cod_com_rbd
				export excel using "$output\230208_dependencia_basica", sheet(basica_com,modify) firstrow(var) cell(F2)
	restore 
	
	*4 - Neteo Comunal
		preserve	
	collapse (sum) def_total2 (first) cod_reg_rbd , by(cod_com_rbd depe)
		sort depe cod_com_rbd
				export excel using "$output\230208_dependencia_basica", sheet(basica_neto_com,modify) firstrow(var) cell(B2)
	restore 

	preserve	
	collapse (sum) def_ido2 (first) cod_reg_rbd  , by(cod_com_rbd depe)
		sort depe cod_com_rbd
				export excel using "$output\230208_dependencia_basica", sheet(basica_neto_com,modify) firstrow(var) cell(F2)
	restore 


