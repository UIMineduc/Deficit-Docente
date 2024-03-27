* Autora: Carla Zúñiga
* Fecha última modificación: 27-03-24
* Código: Cálculo del porcentaje de establecimientos y de matrícula en análisis, 
* además de porcentajes de establecimientos que no están en el análisis


**# Configuración
clear all
set more off
graph set window fontface "Calibri light" // Dejamos calibri light como formato predeterminado 


global main "D:\OneDrive - Ministerio de Educación\Proyectos\2024\Déficit docente"
global Data "$main/Data\2023"
global Matricula "D:\OneDrive - Ministerio de Educación\BBDD\Matricula\2023"
global Output "$main/Output\2023\Nucleares"


**# 1. Cálculo de porcentaje de establecimientos en análisis

	use "$Matricula\matricula_unica_2023.dta", clear
	
	**Se filtra EE en funcionamiento
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
	bys rbd: replace establecimiento_m=establecimiento_m[_N]
	bys rbd: keep if _n==1
	tab establecimiento_m // 43,70% de los establecimientos a nivel nacional
	
	tabstat establecimiento_m, s(mean) f(%9.4f)
	
	
**# 2. Cálculo de porcentaje de matrícula en análisis	
	
	use "$Matricula\matricula_unica_2023.dta", clear

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
	tab establecimiento_m //68,18% de la matrícula a nivel nacional
	
	tabstat establecimiento_m, s(mean) f(%9.4f)

********************************************************************************
	
**# 3. Porcentaje de EE que no están incorporados en el análisis según zona, código de enseñanza, etc.
	
	use "$Matricula\matricula_unica_2023.dta", clear
	
	**Filtramos EE en funcionamiento
	keep if estado_estab==1
	
	**Variables de Interés 
	keep rbd rural_rbd cod_ense2 cod_depe2

	preserve
	gen establecimiento=0
	quietly destring, dpcomma replace
	bys rbd: replace establecimiento=1 if rural_rbd==1
	sort rbd establecimiento
	bys rbd: replace establecimiento=establecimiento[_N]
	bys rbd: keep if _n==1
	tab establecimiento // 28,57% de los establecimientos son rurales
    restore 
	
	preserve
	gen establecimiento=0
	quietly destring, dpcomma replace
	bys rbd: replace establecimiento=1 if rural_rbd==0 & cod_ense2==1
	bys rbd: replace establecimiento=2 if rural_rbd==0 & inlist(cod_ense2,2,5,7)
	sort rbd establecimiento
	bys rbd: replace establecimiento=establecimiento[_N]
	bys rbd: replace establecimiento=0 if establecimiento==2
	bys rbd: keep if _n==1
	tab establecimiento // 4,27% de los establecimientos son educación parvularia urbanos
    restore 	

	preserve
	gen establecimiento=0
	quietly destring, dpcomma replace
	bys rbd: replace establecimiento=1 if rural_rbd==1 & cod_ense2==1
	bys rbd: replace establecimiento=2 if rural_rbd==1 & inlist(cod_ense2,2,5,7)
	sort rbd establecimiento
	bys rbd: replace establecimiento=establecimiento[_N]
	bys rbd: replace establecimiento=0 if establecimiento==2
	bys rbd: keep if _n==1
	tab establecimiento // 0,08% de los establecimientos son educación parvularia rural
	restore
	
	
	preserve
	gen establecimiento=0
	quietly destring, dpcomma replace
	bys rbd: replace establecimiento=1 if rural_rbd==0 & inlist(cod_ense2,3,6,8)
	bys rbd: replace establecimiento=2 if rural_rbd==0 & inlist(cod_ense2,1,2,5,7)
	sort rbd establecimiento
	bys rbd: replace establecimiento=establecimiento[_N]
	bys rbd: replace establecimiento=0 if establecimiento==2
	bys rbd: keep if _n==1
	tab establecimiento // 3,38% de los establecimientos son educación adultos urbanos
	restore		
	
	preserve
	gen establecimiento=0
	quietly destring, dpcomma replace
	bys rbd: replace establecimiento=1 if rural_rbd==0 & cod_ense2==4
	bys rbd: replace establecimiento=2 if rural_rbd==0 & inlist(cod_ense2,1,2,5,7,3,6,8)
	sort rbd establecimiento
	bys rbd: replace establecimiento=establecimiento[_N]
	bys rbd: replace establecimiento=0 if establecimiento==2
	bys rbd: keep if _n==1
	tab establecimiento // 15,64% de los establecimientos son educación especial urbanos
	restore	
	
	
********************************************************************************




