*Horas1 totales matematica

use prueba.dta ,clear

preserve

keep if inlist(subsector1,32001,32002)
collapse (sum) horas1 , by(rbd)

tempfile base1
save `base1' , replace

restore

*Horas1 idoneos totales matematica
preserve

keep if inlist(subsector1,32001,32002)
collapse (sum) horas1 if ido_mat1==1  , by(rbd)
rename horas1 horas1_ido


tempfile base1_ido
save `base1_ido', replace

restore

*Horas2 totales matematica
preserve
keep if inlist(subsector2,32001,32002)
collapse (sum) horas2 , by(rbd)


tempfile base2
save `base2', replace

restore

*Horas2 idoneos totales matematica
preserve
keep if inlist(subsector2,32001,32002)
collapse (sum) horas2 if ido_mat2==1  , by(rbd)
rename horas2 horas2_ido


tempfile base2_ido
save `base2_ido', replace

restore

use `base1',clear
append using `base1_ido'
append using `base2'
append using `base2_ido'
gen subsector1=32001

order subsector1, a(rbd)

bys rbd subsector1: gen id=_n
bys rbd subsector1: egen h1=max(horas1)
bys rbd subsector1: egen h1_ido=max(horas1_ido)
bys rbd subsector1: egen h2=max(horas2)
bys rbd subsector1: egen h2_ido=max(horas2_ido)

keep if id==1
drop id

recode h1 h2 h1_ido h2_ido (.=0)


drop horas*
rename (h1 h2 h1_ido h2_ido) (horas1 horas2 horas1_ido horas2_ido)

gen horas=horas1 + horas2
gen horas_ido=horas1_ido + horas2_ido


save base_matematicas.dta,replace

