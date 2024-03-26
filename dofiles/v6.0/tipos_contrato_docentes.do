**# Directorio

global Docentes "D:\OneDrive - Ministerio de Educación\0 0 Bases de datos - MINEDUC\Docentes\Cargos Docentes"	

	
	use "$Docentes\docentes_2022_publica.dta" ,clear
	
	**Filtramos EE en funcionamiento
	keep if estado_estab==1
	
	**Dropeamos variables que no se ocupan
	drop estado_estab persona
	
	**Variables de Interés 
	keep mrun rbd id_ifp id_ifs cod_ens_1 cod_ens_2 sector1 sector2 subsector1 subsector2 horas_aula horas1 horas2 tip_tit_id_1 tip_tit_id_2 nivel1 nivel2 cod_depe2 cod_reg_rbd cod_com_rbd rural_rbd esp_id_1 esp_id_2 id_itc tip_insti_id_1 tip_insti_id_2 grado*_1 grado*_2 nom_com_rbd horas_contrato
	order cod_reg_rbd cod_com_rbd cod_depe2 rural_rbd rbd mrun

		quietly destring, dpcomma replace
	**Mantenemos solo RBD urbanos
	keep if rural_rbd==0
	keep if cod_depe2!=3
	
		gen contrato=.
		replace contrato=1 if inlist(id_itc,1,2,4) // Titular o Contratado indefinido
		replace contrato=2 if inlist(id_itc,3,7,12,19,20) // reemplazante
		replace contrato=3 if inlist(id_itc,8,5,6) // Honorario o plazo fijo
		replace contrato=4 if inlist(id_itc,9,10,11,13,14,15,16,17,18,21,22) // SEP & PIE
		
		label define tipo_contrato 1 "Titular" 2 "Reemplazante" 3 "Honorario/plazo fijo" 4 "Glosa SEP/PIE"
		label values contrato tipo_contrato
	
		label define tipo_depe 1 "Municipal" 2 "Subvencionado" 4 "CAD" 5 "SLEP"
		label values cod_depe2 tipo_depe
	
	tab contrato
	
	preserve
		keep if inlist(1,id_ifp,id_ifs)
		
		tab contrato cod_depe2,col
	restore
	
	hexplot horas_aula i.contrato i.cod_depe2, statistic(mean) values(format(%9.1f)) xlabel(1 2 3 4) ylabel(1(1)4) cuts(@min(0.5)@max) colors(blues) ///
	title("Promedio horas aula por tipo contrato y dependencia", lalign(center)) ///
	graphregion(c(white)) keylabels(,format(%9.1f) range(1))

	///
colors(plasma, intensity(.6)) p(lc(black) lalign(center))
	
	
	
	
	**# Basica 
	
	preserve
	**Mantenemos a quienes ejercen como docente de aula, de forma primaria y a los que hacen clases en básica. Este se considera el universo de docentes
	keep if inlist(1,id_ifp,id_ifs)
	keep if inlist(110,cod_ens_1,cod_ens_2)
	keep if inlist(sector1,110,115,120,130,140,150,160,170,180,190,310,320,330,340,350,360,370,380,390,395) | inlist(sector2,110,115,120,130,140,150,160,170,180,190,310,320,330,340,350,360,370,380,390,395)
	
	tab contrato
	restore
	
	**# Media
	preserve
	keep if inlist(1,id_ifp,id_ifs)
	keep if inlist(cod_ens_1,310,410,510,610,710,810,910) | inlist(cod_ens_2,310,410,510,610,710,810,910)
	
	keep if inlist(sector1,110,115,120,130,140,150,160,170,180,190,310,320,330,340,350,360,370,380,390,395) | inlist(sector2,110,115,120,130,140,150,160,170,180,190,310,320,330,340,350,360,370,380,390,395)
	
	tab contrato
	restore
	
	