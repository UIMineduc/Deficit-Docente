*Autor: Alonso Arraño
*Fecha ultima modificacion: 29-05-23
*Nota: Este es quizás el proyecto más importante que hice en el CEM, tratenlo con cariño
* Hay un montón de horas y reuniones detrás de este cálculo.


*** Listado de RBD que no reportan docentes en enseñanza básica

clear all
*Directorio AAP

cd "D:\OneDrive - Ministerio de Educación\2022\18 Deficit Docente\Data"

global docentes "D:\OneDrive - Ministerio de Educación\0 0 Bases de datos - MINEDUC\Docentes\Cargos Docentes"
global matricula22 "D:\OneDrive - Ministerio de Educación\0 0 Bases de datos - MINEDUC\Matricula\2022"
global directorio "D:\OneDrive - Ministerio de Educación\0 0 Bases de datos - MINEDUC\Directorios"
global output "D:\OneDrive - Ministerio de Educación\2022\18 Deficit Docente\output\v4"



*3- Determinar cuántos docentes titulados por materia seleccionada ejercen como función principal la docencia de aula en cada rbd.

**#Load Data
	
	*import delimited "$docentes\Docentes_2022_PUBLICA.csv", varnames(1) encoding(UTF-8) clear 
	*save "$docentes\docentes_2022_publica.dta",replace
	
	use "$docentes\docentes_2022_publica.dta" ,clear
	
	keep if estado_estab==1
	
	drop estado_estab persona
	
	*Variables de Interés 
	keep mrun rbd id_ifp id_ifs cod_ens_1 cod_ens_2 sector1 sector2 subsector1 subsector2 horas_aula horas1 horas2 tip_tit_id_1 tip_tit_id_2 nivel1 nivel2 cod_depe2 cod_reg_rbd cod_com_rbd rural_rbd esp_id_1 esp_id_2 id_itc tip_insti_id_1 tip_insti_id_2
	
	order cod_reg_rbd cod_com_rbd cod_depe2 rural_rbd rbd mrun
	
**# Análisis
		* Mantenemos solo RBD urbanos
		keep if rural_rbd==0
		
		* Mantenemos solo docentes titulares y no reemplazantes
		drop if inlist(id_itc,3,7,12,19,20)
		
		* Destring de variables 
		quietly destring, dpcomma replace
		
	*Mantenemos a quienes ejercen como docente de aula, de forma primaria y a los que hacen clases en basica/media
	*Este se considera el universo de docentes
		keep if inlist(110,cod_ens_1,cod_ens_2)


	codebook mrun rbd
	*Tenemos un total de 122.665 personas haciendo clases como universo final de basica usando todos los cargos
	* Con un total de 120.220 obs únicos
	*considerando un total de 4,879 RBD como universo usando ifp + ifs
	
********************************************************************************
********************************************************************************

**# Oferta de horas por RBD y Asignatura
	* Horas totales del establecimiento*
	*Por subsector1
	preserve
			keep if inlist(subsector1,11001,11004,12001,12002,13001,13002,13003,13004,19001)
	collapse (sum) horas1 , by(rbd subsector1)

	tempfile ofta1
	save `ofta1',replace 
	restore
	
	*Por subsector2
	preserve
			keep if inlist(subsector2,11001,11004,12001,12002,13001,13002,13003,13004,19001)
	collapse (sum) horas2, by(rbd subsector2)
	rename subsector2 subsector1

	tempfile ofta2
	save `ofta2',replace 
	restore


	*hasta acá tenemos 4,867 rbd
	*Agregamos la información de la cantidad de horas para cada oferta por rbd
	
	use `ofta1',clear
	append using `ofta2'
		collapse (sum) horas1 horas2 ,by(rbd)
	codebook rbd
	
		tempvar tot_h1
	egen `tot_h1'=total(horas1)
	
		display "horas 1 totales:"
	levelsof `tot_h1'
	
********************************************************************************

	*ajustes del merge
	recode horas1 horas2 (.=0)
	
	*el codebook arroja 4.867 establecimientos
	
**# Horas totales y Horas Lectivas
	*Horas disponibles del RBD
	
	*Acá tenemos el total de horas aula 
	gen hrs_aula2=horas1+horas2
	gen hrs_lect2=hrs_aula2*4*0.65
	
	collapse (sum)   hrs_lect2  , by(rbd)
	
	rename ( hrs_lect2 ) ( ofta_hrs2 )
	
	*El sufijo 2 hace referencia al total de horas
	
	*Nota: Tenemos 4.867 rbd

	gen cod_ense2=2

****************************************************************************


**# Merge Oferta y Demanda de EE

	preserve
	use "dda_hrs_rbd_nivel_2022_38sem.dta",clear
	keep if cod_ense2==2
	keep if rural_rbd==0
	tempfile dda
	save `dda'
	restore

	merge 1:1 rbd cod_ense2 using `dda', keepusing(n_cursos dda_hrs_basica)
	rename _merge merge_dda
	*drop if _merge==1 //50 RBD con docentes pero sin matricula en el nivel. 
	*drop if _merge==2 //24 RBD con cursos pero sin docentes principales
	
	*agregamos data administrativa
	merge 1:1 rbd using "$directorio\directorio_2022",  keepusing(cod_reg_rbd cod_com_rbd cod_depe2) keep(3)
	drop _merge
	
	tab merge_dda cod_depe2
	drop if merge_dda!=3
	drop merge_dda
	
	*Nos quedamos con 4.820 EE completos

**# Cálculo del Deficit
	*Deficit general total
		
	*1 + 2
	gen def_total2=ofta_hrs2-dda_hrs_basica
	replace def_total2=def_total2/(30*0.65)
		
	**# establecimiento en situacion de deficit
	*horas 1+2
	gen d_def_tot2=1 if def_total2<0
		replace d_def_tot2=0 if def_total2>=0
	
	* Redondeo del deficit segun situacion
	
	replace def_total2=ceil(def_total2) if d_def_tot2==0
	replace def_total2=floor(def_total2) if d_def_tot2==1

	*save "ofta_dda_basica_2022",replace
	tempfile simulacion
	save `simulacion'
	
	
**# Base Final

	*use "ofta_dda_basica_2022",clear
	use `simulacion',clear
	
	**# Graficos Horas1 y Horas totales
	**********
	** NOTA: LA MAYORIA DE LAS HORAS SE ENCUENTRAN EN HORAS 1
	
twoway kdensity def_total2  , lp(solid) lcolor("15 105 180"*0.8) lw(medthick) ///
	title("Densidad dif. estimada de docentes en Ens. Básica",color(black) margin(medium) ) ///
	legend(label(1 "Docentes Totales") region(fcolor(none) lcolor(none))) ///
	xtitle("Diferencia docentes estimada") ytitle("Densidad") ///
	graphregion(c(white))
	
graph box def_total2 , ///
	title("Distribución dif. estimada de docentes Educación Básica",color(black) margin(medium)) ///
	legend(label(1 "Docentes Totales")) ///
	graphregion(c(white)) ///
	box(1, color("15 105 180"*0.8)) ///
	nooutsides ytitle("Diferencia") ///
	legend(region(fcolor(none) lcolor(none))) ///
	note("Nota: Se excluyen los valores externos") ///
	yline(0, lpattern(solid) lcolor(black*0.6))
	
	
**# Tablas finales
	*Indicador por region y comuna
	bys cod_com_rbd: gen id_com=_n==1
	bys cod_reg_rbd: gen id_reg=_n==1
	
	*% de EE con déficit por región
		
	*tabstat d_def_tot1 d_def_ido1 d_def_tot2 d_def_ido2, by(cod_reg_rbd)
	tabstat d_def_tot2, by(cod_reg_rbd) s(mean) f(%9.4f)
	
	table cod_reg_rbd d_def_tot2


	**# Total de docentes que faltan por comuna

	*Sumamos solo los valores negativos
	
	*1-NO NETEO! Comunal
	preserve	
	collapse (sum) def_total2 (first) cod_reg_rbd if d_def_tot2==1 , by(cod_com_rbd)
				export excel using "$output\230530_n_def_doc_38sem_2022_todas_horas.xlsx", sheet(basica_com,modify) firstrow(var) cell(B2)
	restore 

**# Analisis por Dependencia
	
	*Definición de Dependencia
	*generamos la dependencia para el CEM entre público y part.sub
	gen depe=.
		replace depe=1 if cod_depe2==1
		replace depe=2 if inlist(cod_depe2,2,4)
		replace depe=3 if cod_depe2==3
		replace depe=4 if cod_depe2==5
		
	label define depe 1 "Público" 2 "Subvencionado" 3 "Particular" 4 "SLEP"
	label  values depe depe
	
	
	**# Tablas
	*NO NETEO! Comunal
	preserve	
	collapse (sum) def_total2 (first) cod_reg_rbd if d_def_tot2==1 , by(cod_com_rbd depe)
	sort depe cod_com_rbd
	export excel using "$output\230530_n_def_doc_38sem_2022_todas_horas.xlsx", sheet(depe_basica,modify) firstrow(var) cell(B2)
	restore 




