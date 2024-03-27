* Autores: Alonso Arraño y Carla Zúñiga
* Fecha última modificación: 27-03-24

clear all
set more off

global Plan "D:\OneDrive - Ministerio de Educación\Proyectos\2024\Déficit docente\Plan de Estudios"

forv i=1/3{
    
import excel "$Plan\plan_de_estudios_2018.xlsx", sheet("CEM_38_crono_v1") cellrange(A1:F25) firstrow case(lower) clear
save "$Plan\plan_de_estudios_2022_38_sem.dta",replace
	
}


