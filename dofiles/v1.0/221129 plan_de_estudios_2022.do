cd "D:\OneDrive - Ministerio de Educación\2022\18 Deficit Docente\Data"

use "plan_de_estudios_2018_fnc.dta", clear

** Generamos las horas de ed básica

gen basica=hist+ cs+ leng+ mate if cod_ense2==2
order basica, b(hist)

** Generamos las horas en cronológicas

foreach var in basica hist cs leng mate{
	replace `var'=`var'*45/60
}


save "plan_de_estudios_2022.dta", replace