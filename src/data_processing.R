library(ggplot2)
library(dplyr)
library(reshape2)
dat <- read.csv("/Users/johnbuckner/github/UDEsWithSpatialReplicates/data/SNI_SubtidalSwath_r.csv")

dat_long <- dat %>% 
  melt(id.var = c("YEAR","PERIOD","SEASON","SITE","ID","TRANSECT"))%>%
  group_by(YEAR,variable,PERIOD,SEASON,SITE)%>% summarize(value = sum(value))

species <- c("MacPyr","MacJuv","MesFra","StrPur","PisGig","PycHel"," PteCal","EisArb","SteOsm")
ggplot(dat_long %>% filter(variable %in% species ),
       aes(x = PERIOD, y = log(value+2), color = as.factor(SITE)))+
  geom_line(linewidth = 1)+theme_classic()+facet_wrap(~variable)+
  scale_color_manual(values = PNWColors::pnw_palette("Bay",n = 6))

species <- c("MacPyr","MacJuv","MesFra","StrPur","PycHel")
ggplot(dat_long %>% filter(variable %in% species ),
       aes(x = PERIOD, y = log(value+2), color = as.factor(SITE)))+
  geom_line(linewidth = 1)+theme_classic()+facet_wrap(~variable)+
  scale_color_manual(values = PNWColors::pnw_palette("Bay",n = 6))

species <- c("MacPyr","MacJuv")
data <- dat_long %>% ungroup()%>%
  filter(variable %in% species) %>% 
  mutate(value = log(value + 2))%>%
  select(PERIOD,SITE,variable,value)%>%
  group_by(variable)%>%
  mutate(value = scale(value))%>%
  dcast(PERIOD+SITE~variable)


write.csv(data,"/Users/johnbuckner/github/UDEsWithSpatialReplicates/data/processed_time_series.csv")




species <- c("MacPyr","MacJuv")
data <- dat_long %>% ungroup()%>%
  filter(variable %in% species) %>% 
  mutate(value = log(value + 2))%>%
  select(PERIOD,SITE,variable,value)%>%
  group_by(variable)%>%
  mutate(value = scale(value))%>%
  dcast(PERIOD~SITE+variable)

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
  filter(variable %in% species) %>% 
  select(PERIOD,SITE,variable,value)%>%
  group_by(variable)%>%
  mutate(value = value/mean(value))%>%
  dcast(PERIOD+SITE~variable)


write.csv(data,"/Users/johnbuckner/github/UDEsWithSpatialReplicates/data/processed_time_series_no_log.csv")



species <- c("MesFra","StrPur","PycHel")
dat_covars <- dat_long %>% ungroup()%>%
  filter(variable %in% species) %>% 
  mutate(value = log(value + 2))%>%
  select(PERIOD,SITE,variable,value)%>%
  group_by(variable)%>%
  mutate(value = scale(value))%>%
  dcast(PERIOD+SITE~variable)



dat_r <- read.csv("/Users/johnbuckner/github/UDEsWithSpatialReplicates/data/SubstrateRugosity_r.csv")

rugosity_dat <- dat_r %>% group_by(SITE)%>%
  summarize(RELIEF = mean(RELIEF))%>%ungroup()%>%
  mutate(RELIEF = (RELIEF - mean(RELIEF))/sd(RELIEF))

dat_covars <- merge(dat_covars,rugosity_dat, by = "SITE")
  
write.csv(dat_covars,"/Users/johnbuckner/github/UDEsWithSpatialReplicates/data/processed_rugosity.csv")



species <- c("StrPur")
dat_covars <- dat_long %>% ungroup()%>%
  filter(variable %in% species) %>% 
  mutate(value = log(value + 2))%>%
  select(PERIOD,SITE,variable,value)%>%
  group_by(variable)%>%
  mutate(value = scale(value))%>%ungroup()%>%
  filter(!is.na(value))%>%
  dcast(PERIOD~SITE+variable)

dat_covars[is.na(dat_covars)] <- 0
write.csv(dat_covars,"/Users/johnbuckner/github/UDEsWithSpatialReplicates/data/covars_wide.csv")

rugosity_dat <- dat_r %>% group_by(SITE)%>%
  summarize(RELIEF = mean(RELIEF))%>%ungroup()%>%
  mutate(RELIEF = (RELIEF - mean(RELIEF))/sd(RELIEF))

dat_covars <- merge(dat_covars,rugosity_dat, by = "SITE")

write.csv(dat_covars,"/Users/johnbuckner/github/UDEsWithSpatialReplicates/data/processed_rugosity.csv")

