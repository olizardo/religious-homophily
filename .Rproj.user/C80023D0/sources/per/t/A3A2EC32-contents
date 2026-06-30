# Header ------------------------------------------------------------------

# Title: plot_compare_2_sims
# Author: Michael Wood
# Created: 20240603
# Last Edited: 20240604
# Purpose: Creates a plot that compares the distributions of the simulated
#           ego networks to the observed. 

# NOTE: Run AFTER create_simulations OR use df_sim_avg_ei.RDS


# Load packages -----------------------------------------------------------

library(here)
library(tidyr)
library(ggplot2)
library(ggbeeswarm)


# Load data ---------------------------------------------------------------

#load data if not already in memory
df_sim_avg_ei <- readRDS(here('data', 'df_sim_avg_ei_500.RDS'))


# Prep data ---------------------------------------------------------------

#give columns unique names

for (i in 2:501){
  colnames(df_sim_avg_ei)[i] <- paste0(names(df_sim_avg_ei[i]),"_",i-1)
}
  
#reshape to long
df_sim_avg_ei <- gather(df_sim_avg_ei, key = sim_num, value = percent, -yourelig_1)

#add column for type
df_sim_avg_ei$type <- "Simulated"
df_observed_avg_ei$type <- "Observed"

# Calculate Z-Scores ------------------------------------------------------

#(x - m)/sd

df_sim_avg_ei %>% 
  group_by(yourelig_1) %>% 
  summarise(mean = mean(percent))

df_sim_avg_ei %>% 
  group_by(yourelig_1) %>% 
  summarise(sd = sd(percent))

df_observed_avg_ei

z_cath <- (-0.622 + 0.460)/0.0284
z_none <- (0.529 - 0.756)/0.0638
z_other<- (0.698 - 0.909)/0.0604
z_prot <- (0.583 - 0.805)/0.0508

#Note, all of the observed values have significant z scores,
#meaning all groups manifest more homophily than expected by chance.


# Comparison plot ---------------------------------------------------------

# Beeswarm plot in ggplot2
ggplot() +
  geom_quasirandom(data = df_sim_avg_ei, aes(x = yourelig_1, y = percent, color = yourelig_1, shape = type), cex=1, width = .5) +
  geom_point(data=df_observed_avg_ei, aes(x=yourelig_1, y=percent, shape = type),  cex=2)+
  scale_color_brewer(palette = "RdYlBu", guide = "none")+
  xlab("\nEgo's Religious Identity")+
  ylab("Average EI Score")+
  theme_minimal()+
  scale_y_continuous(breaks = seq(-1, 1, by = .2), limits=c(-1,1))+
  scale_shape_manual(values = c(18, 16))+
  labs(shape = "Data Type",
       title = "Average EI Scores in Observed vs Simulated Ego Networks\n")+
  geom_hline(yintercept = 0)


ggsave("plot.jpg",
       width = 6.5,
       height = 5,
       units = "in",
       device= "jpg",
       dpi=700)


#optional violin plot
# ggplot(df_sim_avg_ei, aes(x=yourelig_1, y=percent, fill=yourelig_1, shape = type)) + 
#   geom_violin(alpha=.5)+
#   geom_point(data=df_observed_avg_ei)+
# #  geom_boxplot(width=0.1, color="black", alpha=0.2)+
#   xlab("Ego Religion")+
#   ylab("Average EI Index")+
#   theme_minimal()+
#   scale_y_continuous(breaks = seq(-1, 1, by = .1))
