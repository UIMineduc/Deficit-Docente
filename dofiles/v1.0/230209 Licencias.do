


use "D:\Downloads\base_ausencias_marzo_diciembre_trabajada.dta" , clear
drop if agno<2022

levelsof TipodeAusencia
	keep if TipodeAusencia=="Licencia Medica" 
**# Variables de interés

bys doc_run: gen aux=_n //permite obtener la cantidad de docentes con al menos 1 licencia
bys doc_run: egen n_licencias=max(aux) // permite obtener la cantidad de licencias que tiene un docente en el período
bys doc_run: egen mean_dias=mean(dias_lic) // Cantidad de días promedio de licencia por docente
bys doc_run: egen total_dias=total(dias_lic) //cantidad de dias total de licencias por indiv.

save "Licencias_2022.dta", replace

