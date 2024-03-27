* Autores: Alonso Arraño y Carla Zúñiga
* Fecha última modificación: 27-03-24
* Código: Cálculo de la demanda de horas docentes por rbd y asignatura a partir
* de base de matrícula y plan de estudios

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
global Output "$main/Output\2023\Nucleares"



************************** Demanda de horas docentes ***************************

**# 1. Cantidad de cursos distintos por nivel (básica y media)
	
    use rbd cod_reg_rbd cod_com_rbd cod_depe2 rural_rbd cod_ense2 estado_estab cod_jor cod_grado let_cur mrun cod_tip_cur using "$Matricula\matricula_unica_2023.dta", clear
	
	**EE en funcionamiento
	keep if estado_estab==1
	drop estado

	**Se excluyen a los establecimientos particulares pagados
	drop if cod_depe2==3
	
	**Se deben considerar solo los cursos de básica/media
	keep if inlist(cod_ense2,2,5,7)	
	
	**MODIFICACIÓN ESTABLECIMIENTOS TP QUE IMPARTEN ASIGNATURAS DEL PLAN DE FORMACIÓN GENERAL
	
	/// Para el cálculo de dotación docente de asignaturas nucleares se incorporan 
	/// también los establecimientos TP ya que estos igual imparten las asignaturas 
	/// de formación general según lo establecido por el plan de estudios del MINEDUC.

	tab cod_ense2 cod_grado if cod_ense2==7
	replace cod_ense2=5 if cod_ense==7

	**Etiquetas
	label define jorn 1 "Mañana" 2 "Tarde" 3 "Mañana y tarde" 4 "Vesp./Noct." 99 "S/I"
	label value cod_jor jorn
	
	**Jornada
	**Generar una var para JEC y NO JEC (0= media jornada, 1= JEC) supuesto EE
	gen jornada=1
	replace jornada=0 if cod_jor==1 | cod_jor==2 | cod_jor==4 | cod_jor==99
	
	**Variable id_grado para hacer el merge con base de plan de estudios
	egen aux=concat(jornada cod_ense2 cod_grado) if jornada==1
	egen aux2=concat(cod_ense2 cod_grado)  if jornada==0
	
	gen id_grado=aux if jornada==1
	replace id_grado=aux2 if jornada==0
		
	destring id_grado, dpcomma replace
	encode let_cur, gen(letra)
			
	**Se generan variables para el total de cursos
	bys rbd cod_ense2  cod_grado letra:  egen tam_curso=count(mrun) 
	bys rbd cod_ense2  cod_grado letra:  gen n_cursos=1 if _n==1
	keep if n_cursos==1
	
	**Total de cursos por EE
	collapse (sum) n_cursos (mean) tam_curso (first)  jornada id_grado cod_reg_rbd cod_com_rbd cod_depe2 rural_rbd, by(rbd cod_ense2  cod_grado)
	sort rbd id_grado
    save "$Data\nivel_grados_rbd_2023.dta",replace
	
			
**# 2. Cantidad de horas necesarias por nivel para cada rbd utilizando el plan de estudios de 38 semanas.

global ramos_ee "basica hist cs leng mate fg fd ingles educ_fisica educ_tecno filo_relig arte_musica hld total_jor_ense_grado"
global core "basica hist cs leng mate"
global media "hist cs leng mate"



    use "$Data\nivel_grados_rbd_2023.dta", clear
    merge m:1 id_grado using "$Plan\plan_de_estudios_2022_38_sem.dta", keepusing($core) keep(3) nogen

    gen dda_hrs_basica=basica*n_cursos
	foreach var of varlist $media{
	gen dda_hrs_`var'=`var'*n_cursos
	replace dda_hrs_`var'=. if inlist(id_grado,121,122,123,124,125,126,127,128,21,22,23,24,25,26,27,28)
	}

    collapse (sum)  dda_hrs_basica dda_hrs_hist dda_hrs_cs dda_hrs_leng dda_hrs_mate  (first) n_cursos cod_depe2 rural_rbd, by(rbd cod_ense2)
    save "$Data\dda_hrs_rbd_nivel_2023_38sem.dta",replace




