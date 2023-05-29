*Horas1 totales quimica

use prueba.dta ,clear
preserve

keep if inlist(subsector1,35002)
collapse (sum) horas1 (first) subsector1, by(rbd)

tempfile base1
save `base1' , replace

restore

*Horas1 idoneos totales quimica
preserve

keep if inlist(subsector1,35002)
collapse (sum) horas1 (first) subsector1 if ido_quimica1==1  , by(rbd)
rename horas1 horas1_ido

tempfile base1_ido
save `base1_ido', replace

restore

*Horas2 totales quimica
preserve
keep if inlist(subsector2,35002)
collapse (sum) horas2 (first) subsector2, by(rbd)
rename subsector2 subsector1

tempfile base2
save `base2', replace

restore

*Horas2 idoneos totales quimica
preserve
keep if inlist(subsector2,35002)
collapse (sum) horas2 (first) subsector2 if ido_quimica2==1  , by(rbd)
rename horas2 horas2_ido
rename subsector2 subsector1

tempfile base2_ido
save `base2_ido', replace

restore

use `base1',clear
append using `base1_ido'
append using `base2'
append using `base2_ido'


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



save base_quimica.dta,replace
