* Autores: Alonso Arraño y Carla Zúñiga
* Análisis de la distribución entre n° de cursos, tamaños de matricula y cantidad promedio de alumnos por cursos

clear all
set more off

** Directorios

global matricula "D:\OneDrive - Ministerio de Educación\0 0 Bases de datos - MINEDUC\Matricula\2022"

**# Cargamos data

    *import delimited "$matricula\20220908_Matrícula_unica_2022_20220430_WEB", varnames(1) encoding(UTF-8) clear
	    *save "$matricula\matricula_unica_2022.dta"
   * import delimited "$matricula\20221014_Resumen_Matrícula_Curso_2022_20220430_WEB", varnames(1) encoding(UTF-8) clear	
    *save "$matricula\matricula_curso_2022.dta"

    use rbd cod_reg_rbd cod_com_rbd cod_depe2 rural_rbd cod_ense cod_ense2 estado_estab cod_jor cod_grado let_cur mrun cod_tip_cur using "$matricula\matrícula_unica_2022.dta", clear
	
		**EE en funcionamiento
	keep if estado_estab==1
	drop estado

	**Se excluyen a los establecimientos particulares pagados
	drop if cod_depe2==3
	
	**Se deben considerar solo los cursos de básica/media (cod_ense2=2 es Enseñanza Básica Niños y cod_ense2=5 es Enseñanza Media HC Jóvenes)
	keep if inlist(cod_ense2,2,5,7)	
	*replace cod_ense2=5 if cod_ense==7
	
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
			
	
	gen id=1
	collapse (count) mrun (sum) id (first) cod_depe2, by(rbd cod_ense2 cod_ense cod_grado let_cur)
	
	gen n_cursos=1
	collapse (sum) n_cursos mrun (mean) id (first) cod_depe2 , by(rbd cod_ense2 cod_ense cod_grado)
	
	*gen mat_pron = mrun/n_cursos es lo mismo que el mean id
	rename mrun n_mat
	rename id mean_mat
	
	collapse (sum) n_cursos n_mat (first) cod_depe2 , by(rbd cod_ense2)
	
	gen tamaño_promedio= n_mat/n_cursos
	
	 hexplot tamaño_promedio n_mat n_cursos if tamaño_promedio<=45, stat(mean) colors(plasma, reverse)  cut(1(5)45) bins(30) recenter ///
	 xlabel(#10) ylabel(#10) ///
 xtitle("N° de cursos", margin(top)) ytitle("Matricula total", margin(right)) ///
 legend(size(vsmall) subtitle( "Tamaño" "promedio" "curso")) ///
 graphregion(c(white))
 
	 hexplot tamaño_promedio n_mat n_cursos if tamaño_promedio<=45 & cod_ense2==2, stat(mean) colors(plasma, reverse)  cut(1(5)45) bins(30) recenter ///
	 xlabel(#10) ylabel(#10) ///
 xtitle("N° de cursos", margin(top)) ytitle("Matricula total", margin(right)) ///
 legend(size(vsmall) subtitle( "Tamaño" "promedio" "curso")) ///
 graphregion(c(white)) ///
 title("Basica")
 
	 hexplot tamaño_promedio n_mat n_cursos if tamaño_promedio<=45 & cod_ense2==5, stat(mean) colors(plasma, reverse)  cut(1(5)45) bins(30) recenter ///
	 xlabel(#10) ylabel(#10) ///
 xtitle("N° de cursos", margin(top)) ytitle("Matricula total", margin(right)) ///
 legend(size(vsmall) subtitle( "Tamaño" "promedio" "curso")) ///
 graphregion(c(white)) ///
 title("Media")
	

	**NOTA: no podemos graficar scatter plots por la cantidad de observaciones

	anova tamaño_promedio cod_depe2 tamaño_promedio#cod_depe2
	anova tamaño_promedio cod_depe2
	regress, baselevels
	 
