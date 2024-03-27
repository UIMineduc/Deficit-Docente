* Autora: Carla Zúñiga
* Fecha última modificación: 02-01-24



**Cálculo de porcentaje de establecimientos en análisis

	use "$Matricula\matrícula_unica_2022.dta", clear
	
	**Filtramos EE en funcionamiento
	keep if estado_estab==1
	
	**Variables de Interés 
	keep mrun rbd rural_rbd cod_ense2 cod_depe2

	preserve
	quietly destring, dpcomma replace
	sort rbd
	bys rbd: keep if _n==1
	restore 
	
	gen establecimiento_m=0
	quietly destring, dpcomma replace
	bys mrun: replace establecimiento_m=1 if rural_rbd==0 & inlist(cod_ense2,2,5,7) & cod_depe2!=3
	sort rbd establecimiento_m
	*bys rbd: replace establecimiento_m=establecimiento_m[_N]
	*bys rbd: keep if _n==1
	tab establecimiento_m
	
	tabstat establecimiento_m, s(mean) f(%9.4f)
     
	
	
	
	save "$Data\rbd_matricula.dta",replace

	
********************************************************************************

	use "$Docentes\docentes_2022_publica.dta" ,clear
	
	**Filtramos EE en funcionamiento
	keep if estado_estab==1
	
	**Variables de Interés 
	keep rbd rural_rbd cod_ens_*
	
	preserve
	quietly destring, dpcomma replace
	sort rbd
	bys rbd: keep if _n==1 
	restore 
	
	gen establecimiento=0
	quietly destring, dpcomma replace
	bys rbd: replace establecimiento=1 if rural_rbd==0 & (inlist(cod_ens_1,110,310,410,510,610,710,810,910) | inlist(cod_ens_2,110,310,410,510,610,710,810,910))
	sort rbd establecimiento
	bys rbd: replace establecimiento=establecimiento[_N]
	bys rbd: keep if _n==1
	tab establecimiento

	
	save "$Data\rbd_docentes.dta",replace
	merge 1:1 rbd using "$Data\rbd_matricula.dta"


	tab establecimiento_m if _merge==3

********************************************************************************
	
	**Ver distribución de RBD según códigos de enseñanza
	use "$Docentes\docentes_2022_publica.dta" ,clear
	
	**Filtramos EE en funcionamiento
	keep if estado_estab==1
	
	**Variables de Interés 
	keep rbd rural_rbd cod_ens_*
	
	preserve
	gen establecimiento=0
	quietly destring, dpcomma replace
	bys rbd: replace establecimiento=1 if rural_rbd==1
	sort rbd establecimiento
	bys rbd: replace establecimiento=establecimiento[_N]
	bys rbd: keep if _n==1
	tab establecimiento // 28,6% de los establecimientos son rurales
	restore
	
	preserve
	gen establecimiento=0
	quietly destring, dpcomma replace
	bys rbd: replace establecimiento=1 if rural_rbd==0 & (cod_ens_1==10 | cod_ens_2==10)
	bys rbd: replace establecimiento=2 if rural_rbd==0 & (inlist(cod_ens_1,110,310,410,510,610,710,810,910) | inlist(cod_ens_2,110,310,410,510,610,710,810,910))
	sort rbd establecimiento
	bys rbd: replace establecimiento=establecimiento[_N]
	bys rbd: replace establecimiento=0 if establecimiento==2
	bys rbd: keep if _n==1
	tab establecimiento // 5,69% de los establecimientos son educación parvularia urbanos
	restore
	
	
	preserve
	gen establecimiento=0
	quietly destring, dpcomma replace
	bys rbd: replace establecimiento=1 if rural_rbd==1 & (cod_ens_1==10 | cod_ens_2==10)
	bys rbd: replace establecimiento=2 if rural_rbd==1 & (inlist(cod_ens_1,110,310,410,510,610,710,810,910) | inlist(cod_ens_2,110,310,410,510,610,710,810,910))
	sort rbd establecimiento
	bys rbd: replace establecimiento=establecimiento[_N]
	bys rbd: replace establecimiento=0 if establecimiento==2
	bys rbd: keep if _n==1
	tab establecimiento // 0,09% de los establecimientos son educación parvularia rural
	restore
	
	
	preserve
	gen establecimiento=0
	quietly destring, dpcomma replace
	bys rbd: replace establecimiento=1 if rural_rbd==0 & (inlist(cod_ens_1,160,161,163,165,167,360,361,363,460,461,463,470,560,561,563,660,661,663,760,761,763,860,861,863,963) | inlist(cod_ens_2,160,161,163,165,167,360,361,363,460,461,463,470,560,561,563,660,661,663,760,761,763,860,861,863,963))
	bys rbd: replace establecimiento=2 if rural_rbd==0 & (inlist(cod_ens_1,10,110,310,410,510,610,710,810,910) | inlist(cod_ens_2,10,110,310,410,510,610,710,810,910))
	sort rbd establecimiento
	bys rbd: replace establecimiento=establecimiento[_N]
	bys rbd: replace establecimiento=0 if establecimiento==2
	bys rbd: keep if _n==1
	tab establecimiento // 3,44% de los establecimientos son educación adultos urbanos
	restore	
	
	
	preserve
	gen establecimiento=0
	quietly destring, dpcomma replace
	bys rbd: replace establecimiento=1 if rural_rbd==0 & (inlist(cod_ens_1,211,212,213,214,215,216,217,218,219,299) | inlist(cod_ens_2,211,212,213,214,215,216,217,218,219,299))
	bys rbd: replace establecimiento=2 if rural_rbd==0 & (inlist(cod_ens_1,10,110,310,410,510,610,710,810,910,160,161,163,165,167,360,361,363,460,461,463,470,560,561,563,660,661,663,760,761,763,860,861,863,963) | inlist(cod_ens_2,10,110,310,410,510,610,710,810,910,160,161,163,165,167,360,361,363,460,461,463,470,560,561,563,660,661,663,760,761,763,860,861,863,963))
	sort rbd establecimiento
	bys rbd: replace establecimiento=establecimiento[_N]
	bys rbd: replace establecimiento=0 if establecimiento==2
	bys rbd: keep if _n==1
	tab establecimiento // 14,08% de los establecimientos son educación especial urbanos
	restore	
	
	
	
	preserve
	gen establecimiento=0
	quietly destring, dpcomma replace
	bys rbd: replace establecimiento=1 if rural_rbd==0 & (cod_ens_1==0 | cod_ens_2==0)
	bys rbd: replace establecimiento=2 if rural_rbd==0 & (inlist(cod_ens_1,10,110,310,410,510,610,710,810,910,160,161,163,165,167,360,361,363,460,461,463,470,560,561,563,660,661,663,760,761,763,860,861,863,963,211,212,213,214,215,216,217,218,219,299) | inlist(cod_ens_2,10,110,310,410,510,610,710,810,910,160,161,163,165,167,360,361,363,460,461,463,470,560,561,563,660,661,663,760,761,763,860,861,863,963,211,212,213,214,215,216,217,218,219,299))
	sort rbd establecimiento
	bys rbd: replace establecimiento=establecimiento[_N]
	bys rbd: replace establecimiento=0 if establecimiento==2
	bys rbd: keep if _n==1
	tab establecimiento // 1,3% de los establecimientos son no hace clases urbanos
	restore	
	
	
********************************************************************************

	use "$Docentes\docentes_2022_privada.dta" ,clear
	
	**Filtramos EE en funcionamiento
	keep if estado_estab==1
	
	**Dropeamos variables que no se ocupan
	drop estado_estab persona




