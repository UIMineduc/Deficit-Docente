*** Listado de RBD que no reportan docentes en enseñanza básica

clear all
**#Directorio AAP

cd "D:\OneDrive - Ministerio de Educación\2022\18 Deficit Docente\Data"

global docentes "D:\OneDrive - Ministerio de Educación\0 0 Bases de datos - MINEDUC\Docentes\Cargos Docentes"
global matricula22 "D:\OneDrive - Ministerio de Educación\0 0 Bases de datos - MINEDUC\Matricula\2022"
global matricula18 "D:\OneDrive - Ministerio de Educación\0 0 Bases de datos - MINEDUC\Matricula\2018"
global directorio "D:\OneDrive - Ministerio de Educación\0 0 Bases de datos - MINEDUC\Directorios"
global output "D:\OneDrive - Ministerio de Educación\2022\18 Deficit Docente\output\v2"


*3- Determinar cuántos docentes titulados por materia seleccionada ejercen como función principal la docencia de aula en cada rbd.

**#Load Data
	
	*import delimited "$docentes\Docentes_2022_PUBLICA.csv", varnames(1) encoding(UTF-8) clear 
	*save "$docentes\docentes_2022_publica.dta",replace
	
	use "$docentes\docentes_2022_publica.dta" ,clear
	
	keep if estado_estab==1
		
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
		*keep if inlist(1,id_ifp,id_ifs)
		*keep if inlist(310,cod_ens_1,cod_ens_2)
		*keep if inlist(subsector1,31001,31004,32001,32002,33001,33002,35001,35002,35003,35004)

	codebook mrun rbd
	*Tenemos un total de 53,906 docentes como unvierso final de media
	* Universo sin los reemplazos de 53.635  y 52.028 docentes unicos
	*considerando un total de 2,674 RBD como universo
	* total de 2.672 unicos rbd sin reemplazos
	
	bys rbd subsector1: gen rbd_subsector1=_n
	bys rbd: egen dotacion=count(mrun)
	bys rbd subsector1: egen dotacion_asignatura=count(mrun)

	tempvar doc_aula
	bys rbd subsector1: egen `doc_aula'=count(mrun) if id_ifp==1
	bys rbd subsector1: egen doc_primario=max(`doc_aula')
	recode doc_primario(.=0)
	
	tempvar doc_aula
	bys rbd subsector1: egen `doc_aula'=count(mrun) if id_ifs==1
	bys rbd subsector1: egen doc_secundario=max(`doc_aula')
	recode doc_secundario(.=0)
	
	gen docentes=doc_primario + doc_secundario
	
	keep if rbd_subsector1==1
	
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
	 
	 
	 tabstat tasa_*
	 ********************************************************************************
	********************************************************************************
**# Horas totales del establecimiento*
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
	
	use `ofta1',clear
	append using `ofta2'

	
	
	use `ofta1',clear
	append using `ofta1_ido'
	append using `ofta2'
	append using `ofta2_ido'
	
	*ajustes del merge
	recode horas1 horas2 hrs_ido1 hrs_ido2(.=0)
	
	bys rbd subsector1: gen rbd_subsector=_n
	
	bys rbd subsector1: egen aux_hr1=max(horas1)
	bys rbd subsector1: egen aux_hr_ido1=max(hrs_ido1)
	bys rbd subsector1: egen aux_hr2=max(horas2)
	bys rbd subsector1: egen aux_hr_ido2=max(hrs_ido2)
	
	keep if rbd_subsector==1
	
	
	**# Horas totales y Horas Lectivas
	*Horas disponibles del RBD
	*solo horas1
	gen hrs_aula1=aux_hr1
	gen hrs_lect1=hrs_aula1*4*0.65
	
	gen hrs_aula_ido1=aux_hr_ido1
	gen hrs_lect_ido1=hrs_aula_ido1*4*0.65
	
	*horas1 + horas2
	gen hrs_aula2=aux_hr1+aux_hr2
	gen hrs_lect2=hrs_aula2*4*0.65
	
	gen hrs_aula_ido2=aux_hr_ido1+aux_hr_ido2
	gen hrs_lect_ido2=hrs_aula_ido2*4*0.65
	
	*Generamos Asignaturas 
	gen asignatura=1 if inlist(subsector1,31001,31004) // lenguaje
		replace asignatura=2 if inlist(subsector1,32001,32002) // Matemática
		replace asignatura=3 if inlist(subsector1,35001,35002,35003,35004) // Ciencias
		replace asignatura=4 if inlist(subsector1,33001,33002) // Historia
	label var asignatura "Asignatura"
	label define asignaturalbl 1 "Lenguaje" 2 "Matematica" 3 "Ciencias" 4 "Historia"
	label values asignatura asignaturalbl
	
	collapse (sum) horas1 horas2 , by(rbd asignatura)
	
	
	*collapse (sum) hrs_lect1 hrs_lect_ido1 hrs_lect2 hrs_lect_ido2 , by(rbd asignatura)
	
	rename (hrs_lect1 hrs_lect2) (ofta_hrs1 ofta_hrs2)
	rename (hrs_lect_ido1 hrs_lect_ido2) (ofta_hrs_ido1 ofta_hrs_ido2)
	
	bys rbd: gen n_asignaturas=_n
	bys rbd: egen asignacion=max(n_asignaturas)
	
	table asignacion if n_asignaturas==1
	
	tempvar horas1_total
	tempvar horas2_total
	egen `horas1_total'=total(ofta_hrs1)
	
	levelsof `horas1_total'
	* Horas totales 1707037.75*
	* Horas totales 1707037.75
	egen `horas2_total'=total(ofta_hrs2)
	
	levelsof `horas2_total'
	* Horas totales 1828489*
	* Horas totales 1828489