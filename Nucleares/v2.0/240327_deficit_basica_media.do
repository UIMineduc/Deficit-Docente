* Autora: Carla Zúñiga
* Fecha última modificación: 27-03-24
* Código: Se unen bases finales de déficit docente para básica y media con el objetivo 
* de mostrar resultados unificando ambos niveles (porcentaje de EE con déficit por cantidad de 
* asignaturas con déficit)


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



**# 1. Unión de bases básica y media
	use "$Data\240327_ofta_dda_basica_2023",clear
	append using "$Data\240327_ofta_dda_media_2023"
	sort rbd
	
	**Se genera variable que indica la cantidad de asignaturas en las que tiene déficit un establecimiento	
	foreach var in tot leng mat cs hist{
	replace d_def_`var'2=0 if d_def_`var'2==.
	}
	
	bys rbd: gen aux_def=d_def_tot2+d_def_leng2+d_def_mat2+d_def_cs2+d_def_hist2
	bys rbd: egen def_asignatura=total(aux_def)
    bys rbd: keep if _n==1
	
	**Se genera variable dicotómica de EE que tienen déficit en 1, 2, 3, 4 y 5 asignaturas
	forv i=1/5{
	gen def_`i'=0
	replace def_`i'=1 if def_asignatura==`i'
	tab def_`i'
	}
	

**# 2. Resultados en porcentaje de EE con déficit
	
	**Porcentaje de EE con déficit según cantidad de asignaturas con déficit
	preserve
	collapse (mean) def_1 def_2 def_3 def_4 def_5
	export excel using "$Output\240327_porcent_def_asignatura_2023.xlsx", sheet(EE_def_asig,modify) firstrow(var) cell(B2)
	restore
	
	**Porcentaje de EE con déficit según cantidad de asignaturas con déficit por región
	preserve
	collapse (mean) def_1 def_2 def_3 def_4 def_5, by(cod_reg_rbd)
	export excel using "$Output\240327_porcent_def_asignatura_2023.xlsx", sheet(EE_def_asig_reg,modify) firstrow(var) cell(B2)
	restore	
	
	**Definición de Dependencia
	gen depe=.
	replace depe=1 if cod_depe2==1
	replace depe=2 if inlist(cod_depe2,2,4)
	replace depe=3 if cod_depe2==5
	label define depe 1 "Municipal" 2 "Subvencionado" 3 "SLEP"
	label values depe depe

	**Porcentaje de EE con déficit según cantidad de asignaturas con déficit por dependencia
	preserve
	collapse (mean) def_1 def_2 def_3 def_4 def_5, by(depe)
	export excel using "$Output\240327_porcent_def_asignatura_2023.xlsx", sheet(EE_def_asig_depe,modify) firstrow(var) cell(B2)
	restore	
	

	**Porcentaje de EE con déficit según cantidad de asignaturas con déficit por SLEP
	preserve
	collapse (mean) def_1 def_2 def_3 def_4 def_5 if depe==3, by(agno_slep nombre_slep)
	export excel using "$Output\240327_porcent_def_asignatura_2023.xlsx", sheet(EE_def_asig_slep,modify) firstrow(var) cell(B2)
	restore		

	preserve
	collapse (mean) def_1 def_2 def_3 def_4 def_5 if depe==3
	export excel using "$Output\240327_porcent_def_asignatura_2023.xlsx", sheet(EE_def_asig_slep,modify) firstrow(var) cell(J2)
	restore		
	
	
	
	
	
	
	
	



