library(ggplot2)
library(dplyr)
library(reshape2)

dat_kelp_inverts <- read.csv("/Users/johnbuckner/github/UDEsWithSpatialReplicates/data/SNI_SubtidalSwath_r.csv")
dat_sheep_head <- read.csv("/Users/johnbuckner/github/UDEsWithSpatialReplicates/data/CAsheephead_r.csv")

dat <- merge(dat_kelp_inverts,dat_sheep_head, 
             by = c("PERIOD", "YEAR", "SEASON", "SITE"))

dat$SemPul <- dat$ADULT.COUNT
dat <- dat %>% select(-ADULT.COUNT)
head(dat)



dat_long <- dat %>% 
  melt(id.var = c("YEAR","PERIOD","SEASON","SITE","ID","TRANSECT"),
       variable.name = "Species")%>%
  group_by(YEAR,Species,PERIOD,SEASON,SITE)%>% summarize(value = sum(value))

palette_8 <- c("#261657","#02403d","#46998d","#b1ba50","#f0d569","#e68b40","#8f3403","#a32444")
species <- c("MacPyr","MacJuv","MesFra","StrPur","PycHel","PteCal","SemPul")
dat_plt <- dat_long %>% filter(Species %in% species ) %>% group_by(Species,YEAR) %>%
  summarize(value = mean(value)) %>% ungroup() %>% group_by(Species) %>%
  mutate(value= value/max(value))



ggplot(dat_plt,
       aes(x = YEAR, y = value, color = Species))+
  ylab("Releative abundance")+ xlab("Time (Years)")+
  geom_line(linewidth = 0.6)+theme_classic()+facet_wrap(~Species)+
  scale_color_manual(values = palette_8)+
  theme(legend.position = "none")

ggsave("~/documents/san_nic_ts.png", height = 3, width = 5)



palette_6 <- c("#261657","#46998d","#b1ba50","#f0d569","#e68b40","#a32444")
ggplot(dat_long %>% filter(Species %in% species ),
       aes(x = PERIOD, y = log(value+2), color = as.factor(SITE)))+
  geom_line(linewidth = 1)+theme_classic()+facet_wrap(~Species)+
  scale_color_manual(values = palette_6)


dat_long$value[dat_long$value==0] <- 1 

data <- dat_long %>% ungroup()%>%
  filter(Species %in% species ) %>% 
  mutate(value = log(value))%>%
  select(PERIOD,SITE,Species,value)%>%
  group_by(Species)%>%
  mutate(value = scale(value))%>%
  dcast(PERIOD+SITE~Species)


write.csv(data,"/Users/johnbuckner/github/UDEsWithSpatialReplicates/data/processed_time_series.csv")









species <- c("MacPyr","MacJuv")
data <- dat_long %>% ungroup()%>%
  filter(Species %in% species) %>% 
  mutate(value = log(value + 2))%>%
  select(PERIOD,SITE,Species,value)%>%
  group_by(Species)%>%
  mutate(value = scale(value))%>%
  dcast(PERIOD~SITE+Species)

inds = c()
for(i in 1:nrow(data)){
  if(!(any(is.na(data[i,])))){
    inds <- append(inds,i)
  }
}


data <- data[inds,]


write.csv(data,"/Users/johnbuckner/github/UDEsWithSpatialReplicates/data/processed_time_series_wide.csv")



species <- c("MacPyr","MacJuv")
data <- dat_long %>% ungroup()%>%
  filter(Species %in% species) %>% 
  select(PERIOD,SITE,Species,value)%>%
  group_by(Species)%>%
  mutate(value = value/mean(value))%>%
  dcast(PERIOD+SITE~Species)


write.csv(data,"/Users/johnbuckner/github/UDEsWithSpatialReplicates/data/processed_time_series_no_log.csv")



species <- c("MesFra","StrPur","PycHel")
dat_covars <- dat_long %>% ungroup()%>%
  filter(Species %in% species) %>% 
  mutate(value = log(value + 2))%>%
  select(PERIOD,SITE,Species,value)%>%
  group_by(Species)%>%
  mutate(value = scale(value))%>%
  dcast(PERIOD+SITE~Species)



dat_r <- read.csv("/Users/johnbuckner/github/UDEsWithSpatialReplicates/data/SubstrateRugosity_r.csv")

rugosity_dat <- dat_r %>% group_by(SITE)%>%
  summarize(RELIEF = mean(RELIEF))%>%ungroup()%>%
  mutate(RELIEF = (RELIEF - mean(RELIEF))/sd(RELIEF))

dat_covars <- merge(dat_covars,rugosity_dat, by = "SITE")
  
write.csv(dat_covars,"/Users/johnbuckner/github/UDEsWithSpatialReplicates/data/processed_rugosity.csv")



species <- c("StrPur")
dat_covars <- dat_long %>% ungroup()%>%
  filter(Species %in% species) %>% 
  mutate(value = log(value + 2))%>%
  select(PERIOD,SITE,Species,value)%>%
  group_by(Species)%>%
  mutate(value = scale(value))%>%ungroup()%>%
  filter(!is.na(value))%>%
  dcast(PERIOD~SITE+Species)

dat_covars[is.na(dat_covars)] <- 0
write.csv(dat_covars,"/Users/johnbuckner/github/UDEsWithSpatialReplicates/data/covars_wide.csv")

rugosity_dat <- dat_r %>% group_by(SITE)%>%
  summarize(RELIEF = mean(RELIEF))%>%ungroup()%>%
  mutate(RELIEF = (RELIEF - mean(RELIEF))/sd(RELIEF))

dat_covars <- merge(dat_covars,rugosity_dat, by = "SITE")

write.csv(dat_covars,"/Users/johnbuckner/github/UDEsWithSpatialReplicates/data/processed_rugosity.csv")

