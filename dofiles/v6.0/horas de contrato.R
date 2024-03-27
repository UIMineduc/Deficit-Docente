pacman::p_load(tidyverse,data.table,openxlsx,viridis,extrafont)



font_import()
y
loadfonts(quiet = T)

fonts()




"Parametros de figuras"
calibri_light <- "Calibri Light"

# Definir el tema personalizado
theme_calibri_light <- function() {
  theme_minimal() +
    theme(
      text = element_text(family = "Calibri Light"),  # Set Calibri Light as the font for all text
      legend.text = element_text(family = "Calibri Light"),  # Font for legend text
      axis.title = element_text(family = "Calibri Light"),  # Font for axis titles
      axis.text = element_text(family = "Calibri Light"),  # Font for axis text
      plot.title = element_text(family = "Calibri Light", size = 20),  # Font and format for plot title
      plot.subtitle = element_text(family = "Calibri Light", size = 14),  # Font and format for plot subtitle
      panel.background = element_rect(fill = "white", color = NA),  # Set background color to white with no border
      panel.grid.major = element_blank(),  # Remove major grid lines
      panel.grid.minor.x = element_line(color = rgb(0, 0, 0, alpha = 0.3)),
      axis.line = element_line(color = "black", size = 0.5),  # Border lines for main x and y axes
      axis.ticks = element_blank(),  # Remove axis ticks
      panel.border = element_blank()  # Remove panel border
    )
}

theme_set(theme_calibri_light())



path <- "D:/OneDrive - Ministerio de Educación/0 0 Bases de datos - MINEDUC/Docentes/Cargos Docentes/"

files <- list.files(path)
doc_22 <- fread(paste0(path,files[[24]])) %>% rename_all(tolower)

doc_22 <- doc_22 %>% 
  filter(estado_estab==1) %>% 
  filter(cod_depe2!=3) %>% 
  mutate(rural_rbd=ifelse(rbd %in% c(10642,10673,10791,10827),0,rural_rbd)) %>% 
  filter(rural_rbd==0) %>% 
  filter(id_ifp==1|id_ifs==1) %>% 
  filter(!id_itc %in% c(3,7,12,19,20))

doc_22 <- doc_22 %>% 
  select(mrun, rbd,id_itc, id_ifp, id_ifs, cod_ens_1, cod_ens_2, sector1, sector2,
         subsector1, subsector2, horas1, horas2, starts_with("horas_"),
         starts_with("tip_tit_id_"), starts_with("esp_id_"), starts_with("nivel"),
         cod_depe2, cod_reg_rbd, cod_com_rbd, rural_rbd, id_itc, nom_reg_rbd_a,
         starts_with("grado"))

"Data manipulation"
vars <- c("horas_contrato","horas_direct", "horas_tec_ped", "horas_aula", "horas_dentro_estab", "horas_fuera_estab")

doc_22 <- doc_22 %>%
  mutate(across(starts_with("horas_"), ~if_else(. == 0, NA_real_, .)),
         horas_contrato = if_else(horas_contrato == 0, NA_real_, horas_contrato))

doc_22 <- doc_22 %>%
  mutate(cod_depe2 = recode_factor(cod_depe2,
                                   "1" = "Municipal",
                                   "2" = "Part. Subv.",
                                   "3" = "Part. Pagado",
                                   "4" = "CAD",
                                   "5" = "SLEP"))


doc_22_box <- doc_22 %>% select(mrun,rbd,all_of(vars),cod_depe2,sector1,sector2)
doc_22_box <- gather(doc_22_box, key = "variable", value = "value", vars)

aux <- doc_22_box %>% filter(variable=="horas_contrato") %>% select(c("mrun","rbd","value"))
doc_22_box <- left_join(doc_22_box,aux,by=c("mrun","rbd"))

rm(aux)

doc_22_box <- doc_22_box %>% filter(variable!="horas_contrato") %>% 
  mutate(proporcion=round(value.x*100/value.y,2)) %>% 
  filter(is.na(proporcion)==FALSE)

doc_22_box$variable <- factor(doc_22_box$variable, levels = unique(doc_22_box$variable), labels = c("Directivas","Tec. Ped.", "Aula", "Dentro Estab.","Fuera Estab."), ordered = TRUE)

# Distribucion horas sobre el total ---------------------------------------

## Todos los docentes -----------------------------------------------------
## Nombres variables
counts <- doc_22_box %>%
  group_by(variable) %>%
  summarize(count = n())

fig1_a <- ggplot(doc_22_box, aes(x=variable, y=proporcion, fill=variable)) +
  geom_boxplot(alpha=0.7, outlier.shape = NA, position = position_dodge(width = 0.75)) +
  stat_summary(fun=mean, geom="point", shape=20, size=4, color="red", fill="red") +
  scale_fill_brewer(palette="Set1") +
  labs(title = "Proporción sobre horas de contrato por función",
       caption="El punto representa el promedio de dicha variable")
 
fig1_a


doc_22_box %>% group_by(variable) %>% summarize(observaciones=n())
aux <- doc_22_box  %>% summarize(observaciones=n(), .by=c(rbd,mrun,variable)) %>% summarize(observaciones=n(), .by=c(variable))



fig2_a <- ggplot(doc_22_box, aes(x=variable, y=proporcion, fill=variable)) +
  geom_boxplot(alpha=0.7,outlier.shape = NA, position = position_dodge(width = 0.75)) +
  stat_summary(fun=mean, geom="point", shape=20, size=4, color="black", fill="white") +
  scale_fill_brewer(palette="Set1") +
  labs(title = "Proporción sobre horas contrato según tipo de hora y dependencia")+
  facet_wrap(~ cod_depe2)
fig2_a
# Gráfico de distribución de violín
fig1_b <- ggplot(doc_22_box, aes(x=variable, y=proporcion, fill=variable)) +
  geom_violin(alpha=0.7) +
  scale_fill_brewer(palette="Set1") +
  labs(title = "Gráfico de distribución de violín")
fig1_b
fig1_b <- ggplot(doc_22_box, aes(x=variable, y=proporcion, fill=variable)) +
  geom_violin(alpha=0.7) +
  scale_fill_brewer(palette="Set1") +
  labs(title = "Gráfico de distribución de violín")+
  facet_wrap(~ cod_depe2)

## solo docentes de asignaturas nucleares -----------------------------------------------------
rm(doc_22_box)


"Esta sección no la corroboré
De aqui para abajo está en testeo"


# Básica ------------------------------------------------------------------
# Definimos Asignaturas clave
asignaturas <- c(110,115,120,130,140,150,160,170,180,190,310,320,330,340,350,360,370,380,390,395)

"Dejamos solo observaciones de basica"
basica <- doc_22 %>% 
  filter(sector1 %in% asignaturas |sector2 %in% asignaturas )

"Asignamos NHA a obs que reportan horas para subsectores del analisis pero de otro nivel de enseñanza"
basica <- basica %>% 
  mutate(subsector1=ifelse(cod_ens_1!=110,NA_real_,subsector1),
         subsector2=ifelse(cod_ens_2!=110,NA_real_,subsector2))

n_distinct(basica$mrun)

basica <- basica %>% 
  mutate(titulo_pedagogia=ifelse(tip_tit_id_1 %in% c(13,15,16)| tip_tit_id_2 %in% c(13,15,16),1,0),
         titulo_media=ifelse(tip_tit_id_1==14|tip_tit_id_2==14,1,0))#Titulo en pedagogia
 
 basica <- basica %>%
  mutate(
    clases_1_5_8 = if_else(cod_ens_1 == 110 & apply(select(., starts_with("grado") & ends_with("_1")), 1, function(row) any(row %in% c(5, 6, 7, 8))), 1, 0),
    clases_2_5_8 = if_else(cod_ens_2 == 110 & apply(select(., starts_with("grado") & ends_with("_2")), 1, function(row) any(row %in% c(5, 6, 7, 8))), 1, 0)
  ) 
 
 subsectores_clave <- c(11001,11004,12001,12002,13001,13002,13003,13004,19001) 

 basica <- basica %>%
   mutate(
     ido_bas1 = ifelse(subsector1 %in% subsectores_clave,1,0),
     ido_bas1 = ifelse(titulo_pedagogia == 1 & subsector1 %in% subsectores_clave , 1, ido_bas1),
     ido_bas1 = ifelse(titulo_media == 1 & clases_1_5_8 == 1 & subsector1 %in% subsectores_clave, 1, ido_bas1)
   ) %>% 
   mutate(
     ido_bas2 = ifelse(subsector2 %in% subsectores_clave,1,0),
     ido_bas2 = ifelse(titulo_pedagogia == 1 & subsector2 %in% subsectores_clave , 1, ido_bas1),
     ido_bas2 = ifelse(titulo_media == 1 & clases_2_5_8 == 1 & subsector2 %in% subsectores_clave, 1, ido_bas2)
   ) 

 summary(basica$ido_bas1)
 summary(basica$ido_bas2)
 





  ## Distribucion habilitados

# Media

  ## Distribucion habilitados


