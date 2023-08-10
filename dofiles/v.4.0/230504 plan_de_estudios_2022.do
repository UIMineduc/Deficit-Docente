cd "D:\OneDrive - Ministerio de Educación\2022\18 Deficit Docente\Data"

global plan "D:\OneDrive - Ministerio de Educación\2022\18 Deficit Docente\Plan de Estudios"

*Load Data

import excel "$plan\plan_de_estudios_2018_fnc.xlsx", sheet("CEM_10_crono") cellrange(A1:F25) firstrow case(lower) clear

save "plan_de_estudios_2022_10_m.dta"

import excel "$plan\plan_de_estudios_2018_fnc.xlsx", sheet("CEM_38_crono") cellrange(A1:F25) firstrow case(lower) clear

save "plan_de_estudios_2022_38_sem.dta"