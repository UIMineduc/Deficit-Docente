*Directorio AAP

cd "D:\OneDrive - Ministerio de Educación\2022\18 Deficit Docente\Data"

global docentes "D:\OneDrive - Ministerio de Educación\0 0 Bases de datos - MINEDUC\Docentes\Cargos Docentes"
global matricula22 "D:\OneDrive - Ministerio de Educación\0 0 Bases de datos - MINEDUC\Matricula\2022"
global matricula18 "D:\OneDrive - Ministerio de Educación\0 0 Bases de datos - MINEDUC\Matricula\2018"
global JEC "D:\OneDrive - Ministerio de Educación\0 0 Bases de datos - MINEDUC\Establecimientos\JEC"


********************************************************************************
*****************Demanda de horas docentes por grado y rbd *********************
********************************************************************************
**# 1 - Cantidad de cursos distintos por nivel (básica y media)
	
	*import delimited "$matricula22\matricula_estudiante_mrun_2022", varnames(1) encoding(UTF-8) clear
	*save "$matricula22\matricula_estudiante_mrun_22.dta"

	use rbd cod_reg_rbd cod_com_rbd cod_depe2 rural_rbd cod_ense2 estado_estab cod_jor cod_grado let_cur mrun cod_tip_cur using "$matricula22\matricula_estudiante_mrun_22.dta", clear
	* Data Management

	* EE en funcionamiento
	keep if estado_estab==1
		drop estado
	*Eliminamos cursos multigrado
	*drop if cod_tip_cur!=0
	
	*Debemos considerar solo los cursos de básica/media (cod_ense2=2 es Enseñanza Básica Niños y cod_ense2=5 es Enseñanza Media Humanístico Científica Jóvenes)
	
	keep if inlist(cod_ense2,2,5)
	
	* Etiquetas
	label define jorn 1 "Mañana" 2 "Tarde" 3 "Mañana y tarde" 4 "Vesp./Noct." 99 "S/I"
	label value cod_jor jorn
	
	*Jornada
	//Generar una var para JEC y NO JEC (0= media jornada, 1= JEC) supuesto EE
	gen jornada=1
	replace jornada=0 if cod_jor==1 | cod_jor==2 | cod_jor==4 | cod_jor==99
	
	*Variable id_grado para hacer el merge
	egen aux=concat(jornada cod_ense2 cod_grado) if jornada==1
	egen aux2=concat(cod_ense2 cod_grado)  if jornada==0
	
	gen id_grado=aux if jornada==1
	replace id_grado=aux2 if jornada==0
		
	destring id_grado, dpcomma replace
	encode let_cur, gen(letra)
			
	* Ggeneramos variables para el total de cursos
	bys rbd cod_ense2  cod_grado letra:  egen tam_curso=count(mrun) 
	bys rbd cod_ense2  cod_grado letra:  gen n_cursos=1 if _n==1
	keep if n_cursos==1
	
	* total de cursos por EE
	collapse (sum) n_cursos (mean) tam_curso (first)  jornada id_grado cod_reg_rbd cod_com_rbd cod_depe2 rural_rbd, by(rbd cod_ense2  cod_grado)

*save "nivel_grados_rbd_2022.dta",replace

**# 2- Determinar la cantidad de horas teóricas de materias seleccionadas (matemáticas, lenguaje, ciencias, sociedad) necesarios por nivel para cada rbd.
sort rbd id_grado

****************************************************************************
*****************  dda horas por rbd y nivel 
****************************************************************************
global ramos_ee "basica hist cs leng mate fg fd ingles educ_fisica educ_tecno filo_relig arte_musica hld total_jor_ense_grado"
global core "basica hist cs leng mate"
global media "hist cs leng mate"

sort rbd id_grado
merge m:1 id_grado using "plan_de_estudios_2022_10_m.dta", keepusing($core) keep(3) nogen

	**# Demanda de horas
	
gen dda_hrs_basica=basica*n_cursos

	foreach var of varlist $media{
	gen dda_hrs_`var'=`var'*n_cursos
	replace dda_hrs_`var'=. if inlist(id_grado,121,122,123,124,125,126,127,128,21,22,23,24,25,26,27,28)
}

collapse (sum)  dda_hrs_basica dda_hrs_hist dda_hrs_cs dda_hrs_leng dda_hrs_mate  (first) n_cursos cod_depe2 rural_rbd, by(rbd cod_ense2)


save "dda_hrs_rbd_nivel_2022_10m.dta",replace


/* Esta sección ya no se considera, pero dejo el código para futuras revisiones
****************************************************************************
*****************  dda horas regionales
****************************************************************************
global ramos_ee "basica hist cs leng mate fg fd ingles educ_fisica educ_tecno filo_relig arte_musica hld total_jor_ense_grado"
use "nivel_grados_rbd_2018.dta" ,clear

merge m:1 id_grado using "plan_de_estudios_2018.dta", keepusing($ramos_ee) keep(3)

	foreach var of varlist $ramos_ee{
	gen dda_hrs_`var'=`var'*n_cursos
}


collapse (sum)  dda_hrs_basica n_cursos  , by(cod_reg_rbd cod_ense2)

save "dda_hrs_reg_2022.dta",replace

****************************************************************************
*****************  dda horas comunales
****************************************************************************
global ramos_ee "basica hist cs leng mate fg fd ingles educ_fisica educ_tecno filo_relig arte_musica hld total_jor_ense_grado"
use "nivel_grados_rbd_2018.dta" ,clear

merge m:1 id_grado using "plan_de_estudios_2018.dta", keepusing($ramos_ee) keep(3)

	foreach var of varlist $ramos_ee{
	gen dda_hrs_`var'=`var'*n_cursos
}


collapse (sum)  dda_hrs_basica n_cursos  , by(cod_com_rbd cod_ense2)

save "dda_hrs_com_2022.dta",replace
*/