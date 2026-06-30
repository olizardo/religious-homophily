
# Header ------------------------------------------------------------------


# Load Packages -----------------------------------------------------------


# Load Data ---------------------------------------------------------------


# Create Data Frames for egor ---------------------------------------------

df_w3_comb_sub <- df_w3_comb_data |> 
  select(egoid,alterid,yourelig_1,altrelig,same_relig)

install.packages("lme4")
library(lme4)
model <- glmer(same_relig ~ altrelig + yourelig_1 + (1 | egoid), data=df_w3_comb_sub,
               family=binomial(link="logit"))
summary(model)

model <- glmer(white ~ homework + (1 + homework | schid), data=mlmdata,
               family=binomial(link="logit"))
summary(model)



df_altrelig_miss <- df_w3_comb_sub |> 
  filter(is.na(altrelig))

df_altrelig_miss <- df_altrelig_miss |> 
  mutate(ego_alt = paste0(egoid, "-", alterid))

char_egoalt_miss <- as.character(df_altrelig_miss$ego_alt)

df_alter_alter_ties <- df_alter_alter_ties |> 
  mutate(ego_v1 = paste0(egoid, "-", vertex1))

df_alter_alter_ties <- df_alter_alter_ties |> 
  mutate(ego_v2 = paste0(egoid, "-", vertex2))



df_alter_alter_ties <- df_alter_alter_ties |> 
  filter(!ego_v1 %in% char_egoalt_miss & !ego_v2 %in% char_egoalt_miss)

df_alter_alter_ties <- df_alter_alter_ties |> 
  filter(egoid %in% char_egoids)


df_egos <- df_w3_comb_data |> 
  select(egoid, yourelig_1) |> 
  unique()

df_egos <- df_egos |> 
  rename("relig"="yourelig_1")

char_egoids <- as.character(df_egos$egoid)


df_alters <- df_w3_comb_data |> 
  select(alterid, egoid, altrelig)

df_alters <- df_alters |> 
  rename("relig"="altrelig")

char_alterids <- as.character(df_alters$alterid)

df_alter_alter_ties <- df_alter_alter_ties |> 
  filter(egoid %in% char_egoids & vertex1 %in% char_alterids & vertex2 %in% char_alterids)


df_alter_alter_ties <- df_alter_alter_ties |> 
  select(-wave)

g_egor <- egor(df_alters, 
                  df_egos, 
                  df_alter_alter_ties,
                  ID.vars = list(ego = "egoid", 
                                 alter = "alterid", 
                                 source = "vertex1",
                                 target =  "vertex2"))


df_EI <- EI(g_egor, "relig", rescale = FALSE)

EI(object, alt.attr, include.ego = FALSE, ego.attr = alt.attr, rescale = TRUE)






library(egor)
data("egos32")
data("alters32")
data("aaties32") 

egor_test <- egor(alters32, 
     egos32, 
     aaties32,
     ID.vars = list(ego = ".EGOID", 
                    alter = ".ALTID", 
                    source = ".SRCID",
                    target =  ".TGTID"))

data("egor32")
EI32 <- EI(egor32, "sex", rescale = FALSE)

EI32 <- comp_ei(egor32, "sex", "sex")
