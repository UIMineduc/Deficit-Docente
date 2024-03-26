**# Directorio

global Docentes "D:\OneDrive - Ministerio de Educación\0 0 Bases de datos - MINEDUC\Docentes\Cargos Docentes"	

	
	use "$Docentes\docentes_2022_publica.dta" ,clear
	
	**Filtramos EE en funcionamiento
	keep if estado_estab==1
	
	**Dropeamos variables que no se ocupan
	drop estado_estab persona
	
	**Variables de Interés 
	keep mrun rbd id_ifp id_ifs cod_ens_1 cod_ens_2 sector1 sector2 subsector1 subsector2 horas_aula horas1 horas2 tip_tit_id_1 tip_tit_id_2 nivel1 nivel2 cod_depe2 cod_reg_rbd cod_com_rbd rural_rbd esp_id_1 esp_id_2 id_itc tip_insti_id_1 tip_insti_id_2 grado*_1 grado*_2 nom_com_rbd
	order cod_reg_rbd cod_com_rbd cod_depe2 rural_rbd rbd mrun

	**Mantenemos solo RBD urbanos
	keep if rural_rbd==0
	keep if cod_depe2!=3
	
	**Mantenemos solo docentes titulares y no reemplazantes
	drop if inlist(id_itc,3,7,12,19,20)
		
	**Destring de variables 
	quietly destring, dpcomma replace
	
**# Basica	
{
preserve
	**Mantenemos a quienes ejercen como docente de aula, de forma primaria y a los que hacen clases en básica. Este se considera el universo de docentes
	keep if inlist(1,id_ifp,id_ifs)
	keep if inlist(110,cod_ens_1,cod_ens_2)
	keep if inlist(sector1,110,115,120,130,140,150,160,170,180,190,310,320,330,340,350,360,370,380,390,395) | inlist(sector2,110,115,120,130,140,150,160,170,180,190,310,320,330,340,350,360,370,380,390,395)

	*br cod_ens_1 subsector1 sector1 cod_ens_2 subsector2 sector2 horas1 horas2 if !inlist(cod_ens_1,110) 
	*sort subsector1
	
	**Se le asigna missing value a las observaciones que reportan horas para los subsectores incluidos en el análisis, pero que corresponden a otros códigos de enseñanza
	forv i=1/2{
	replace subsector`i'=. if !inlist(cod_ens_`i',110)
	}
	
	tab cod_ens_2 subsector2 if !inlist(cod_ens_2,110)

	codebook mrun rbd
	**Tenemos un total de 114.458 docentes como universo final de basica usando ifp + ifs
	**Con un total de 112.200 únicos
	**Considerando un total de 4,871 RBD como universo usando ifp + ifs
	
**************************** Criterios de Idoneidad ****************************
	
**# Idoneidad Docente

    **Condiciones para considerar:
	**La primera condicion (0) son docentes que hacen clases en el nivel de básica en alguna de estas asignaturas
	**La segunda condicion (1) son docentes que hacen clases y que además tienen la titulación según la ley n°....
	
	**Condicion de titulación
	**Se consideran a los titulados en Básica, Parvularia y Básica, y Básica y Media para básica y sólo título en Media para media
	gen titulo_pedagogia= 1 if (inlist(tip_tit_id_1,13,15,16) | inlist(tip_tit_id_2,13,15,16))
	gen titulo_media=1 if tip_tit_id_1==14|tip_tit_id_2==14
	
	**Condición de hacer clases en 5to a 8vo basico
	forv j=1/2{
	forv i=5/8{
		gen clases_`i'_`j'=1 if cod_ens_`j'==110 & inlist(`i',grado1_`j',grado2_`j',grado3_`j',grado4_`j', grado5_`j', grado6_`j', grado7_`j', grado8_`j', grado9_`j', grado10_`j', grado11_`j', grado12_`j')
	}
	gen d_clases_5_8_`j'=1 if inlist(1,clases_5_`j', clases_6_`j', clases_7_`j', clases_8_`j')
	}
	drop clases_*
	
	**Condición de asignaturas (lenguaje, matemáticas, ciencias, historia & general)
	**Explicación: Genero una variable ido_bas1 o ido_bas2 según el subsector1 o 2 en que hace clases. Luego le asigno el 0 a todos aquellos que declaran hacer clases en alguna de las asignaturas de Ens. Basica explicadas arriba. Asigno 1 a los Idóneos con especialidad, que cumplen la condición de hacer clases en el nivel & tienen la pedagogia en básica
	
	global listado1 inlist(subsector1,11001,11004,12001,12002,13001,13002,13003,13004,19001) 
	global listado2 inlist(subsector2,11001,11004,12001,12002,13001,13002,13003,13004,19001) 
	
	forv i=1/2{
	gen ido_bas`i'= 0 if inlist(subsector`i',11001,11004,12001,12002,13001,13002,13003,13004,19001) 
	replace ido_bas`i'=1 if titulo_pedagogia==1  & inlist(subsector`i',11001,11004,12001,12002,13001,13002,13003,13004,19001)
	replace ido_bas`i'=1 if titulo_media==1 & d_clases_5_8_`i'==1 & inlist(subsector`i',11001,11004,12001,12002,13001,13002,13003,13004,19001) 
	}
	
	**Tasa de especialidad
	**NOTA: en este caso se ignoran los casos en los que un docente hace clases, pero no tiene la especialidad (ido_bas=0) en un subsector, y en el otro sí tiene la especialidad (ido_bas=1) y se considera solamente el mayor (en este caso que sí tiene la especialidad). Esto es posible que genere una tasa de especialidad subestimada, dado que no estoy incorporando en el universo a estos docentes que hacen clases en un subsector en el cual no tienen la especialidad.
	
	**Variable que agrupa subsector1 y subsector2 y asigna el mayor valor, en este caso sí se tiene la especialidad
	egen tasa_especialidad=rowmax(ido_bas1 ido_bas2)
	
	tab ido_bas1 // proporción de Idóneos es el 78,79%
	tab ido_bas2 // proporción de Idóneos es el 80,91%
	tab tasa_especialidad // proporción de Idóneos con especialidades el 79,38%
	tab tasa_especialidad cod_depe2 // proporción de Idóneos con especialidades el 79,38%
	
restore
}



**# Media

	keep if inlist(cod_ens_1,310,410,510,610,710,810,910) | inlist(cod_ens_2,310,410,510,610,710,810,910)
	
	keep if inlist(sector1,110,115,120,130,140,150,160,170,180,190,310,320,330,340,350,360,370,380,390,395) | inlist(sector2,110,115,120,130,140,150,160,170,180,190,310,320,330,340,350,360,370,380,390,395)

	
	*br cod_ens_1 subsector1 sector1 cod_ens_2 subsector2 sector2 horas1 horas2 if !inlist(cod_ens_1,110,310,410,510,610,710,810,910) 
	*sort subsector1
	
	**Se le asigna missing value a las observaciones que reportan horas para los subsectores incluidos en el análisis, pero que corresponden a otros códigos de enseñanza
	forv i=1/2{
	replace subsector`i'=. if !inlist(cod_ens_`i',310,410,510,610,710,810,910)
	}
	
	
	tab cod_ens_1 subsector1 if !inlist(cod_ens_1,310,410,510,610,710,810,910)
	
	codebook mrun rbd
	**Total de 61.242 de observaciones de docentes únicos y un total de 63.347 de docentes totales
	**Total de EE que imparten ed. media HC es de 2.880 RBD (sin reemplazos)
	
**************************** Criterios de Idoneidad ****************************
	
**# Idoneidad Docente

    **Condición de titulación
	**Titulado en media y especialidad de la asignatura
	gen titulo_leng=1 if (inlist(tip_tit_id_1,14,16) & inlist(esp_id_1,141,1605)) | ( inlist(tip_tit_id_2,14,16) &  inlist(esp_id_2,141,1605))
	
	gen titulo_mat=1 if (inlist(tip_tit_id_1,14,16) & inlist(esp_id_1,142,1606)) | 	( inlist(tip_tit_id_2,14,16) &  inlist(esp_id_2,142,1606))
	
	gen titulo_fisica=1 if (inlist(tip_tit_id_1,14) & inlist(esp_id_1,143)) |  (inlist(tip_tit_id_2,14) & inlist(esp_id_2,143))
	
	gen titulo_quimica=1 if (inlist(tip_tit_id_1,14) & inlist(esp_id_1,144)) |  (inlist(tip_tit_id_2,14) & inlist(esp_id_2,144))
	
	gen titulo_biologia=1 if (inlist(tip_tit_id_1,14) & inlist(esp_id_1,145,146)) |  (inlist(tip_tit_id_2,14) & inlist(esp_id_2,145,146))
	
	gen titulo_historia=1 if (tip_tit_id_1==14 & esp_id_1==148) | (tip_tit_id_2==14 & esp_id_2==148)
	

	**Condición de asignaturas
	**Explicación: Genero una variable ido_asignatura1 o ido_asignatura2 según el subsector1 o 2 en que hace clases (y la asignatura). Luego le asigno el 0 a todos aquellos que declaran hacer clases en alguna de las asignaturas. Asigno 1 a los Idóneos con especialidad, que cumplen la condición de tener el título de pedagogia en educación media y que tienen la especialidad de la asignatura que imparten
	

	**# Ed Media Lenguaje
	**Realiza o no clases en Lenguaje
	**Toma valor 0 si es que hace clases pero no tiene el título de la especialidad, y 1 si es que hace clases y tiene el título respectivo
	forv i=1/2{
	gen ido_leng`i'=0 if inlist(subsector`i',31001,31004)
	replace ido_leng`i'=1 if titulo_leng==1 & inlist(subsector`i',31001,31004)
	}
	
	
	**Tasa de especialidad en Lenguaje
	**Variable que agrupa subsector1 y subsector2 y asigna el valor máximo
	egen tasa_leng=rowmax(ido_leng1 ido_leng2)
	tab cod_depe2 if tasa_leng!=.
	tab cod_reg_rbd if tasa_leng!=.
	tab tasa_leng

	 
	**# Ed Media Matematica
    **Realiza o no clases en Matemática
	forv i=1/2{
	gen ido_mat`i'=0 if inlist(subsector`i',32001,32002)
	replace ido_mat`i'=1 if titulo_mat==1 & inlist(subsector`i',32001,32002)
	}
	
	**Tasa de especialidad en Matemática
	egen tasa_mat=rowmax(ido_mat1 ido_mat2)	
	tab cod_depe2 if tasa_mat!=.
	tab cod_reg_rbd if tasa_mat!=.
	tab tasa_mat

    **# Ed Media Ciencias
	**#Física
	forv i=1/2{
	gen ido_fisica`i'=0 if inlist(subsector`i',35003,35004)
	replace ido_fisica`i'=1 if titulo_fisica==1 & inlist(subsector`i',35003,35004)
	}
	
	egen tasa_fisica=rowmax(ido_fisica1 ido_fisica2)	
		
	**#Química
	forv i=1/2{
	gen ido_quimica`i'=0 if inlist(subsector`i',35002,35004)
	replace ido_quimica`i'=1 if titulo_quimica==1 & inlist(subsector`i',35002,35004)
	}
	
	egen tasa_quimica=rowmax(ido_quimica1 ido_quimica2)	
	
	**#Biología
	forv i=1/2{
	gen ido_biologia`i'=0 if inlist(subsector`i',35001,35004) 
	replace ido_biologia`i'=1 if titulo_biologia==1 & inlist(subsector`i',35001,35004)
	}

	egen tasa_biologia=rowmax(ido_biologia1 ido_biologia2)	
	
	**#Ciencias General
	forv i=1/2{
	egen ido_cs`i'=rowmax(ido_fisica`i' ido_quimica`i' ido_biologia`i')
		}

	egen tasa_cs=rowmax(ido_cs1 ido_cs2)
	tab cod_depe2 if tasa_cs!=.
	tab cod_reg_rbd if tasa_cs!=.
	
	**# Ed Media Historia
	forv i=1/2{
	gen ido_hist`i'=0 if inlist(subsector`i',33001,33002)
	replace ido_hist`i'=1 if titulo_historia==1 & inlist(subsector`i',33001,33002)
		}
		
	egen tasa_hist=rowmax(ido_hist1 ido_hist2)
	tab cod_depe2 if tasa_hist!=.
	tab cod_reg_rbd if tasa_hist!=.
	
	
	**Variable idoneidad 
	
	/// NOTA: Variable dummy que indica si el docente es idóneo para su asignatura o no,  
	/// es decir, agrupa docentes habilitados y docentes con la especialidad 
	/// (ido_asignatura=0 e ido_asignatura=1). Se usará para sumar las horas idóneas por
	/// asignatura más adelante
	
	/// la jornada laboral debería durar 36 horas uwu :(

	forv i=1/2{
	gen doc_ido`i'=1 if inlist(1,ido_leng`i',ido_mat`i',ido_cs`i',ido_hist`i')
			}
			
	egen max_ido=rowmax(doc_ido1 doc_ido2)

	foreach var of varlist  tasa_* {
	tab `var'
	 }
	 
	*lenguaje 76,22
	*mate 79,16
	*fisica 45,28
	*quimica 54,46
	*biologia 76,53
	*ciencias 70,40
	*historia 90,06
	tabstat tasa_*, by(cod_depe2)
	 