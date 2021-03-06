library(tidyr)
library(dplyr)
library(ggplot2)
library(plotrix)

this_theme<-theme_bw()+
  theme(#panel.grid.major = element_blank(),
    #panel.grid.minor = element_blank(),
    panel.background = element_blank(),
    axis.line = element_line(),
    legend.position='none', legend.title=element_blank(),
    legend.text = element_text(size=12),
    axis.title.x = element_text(size=22,vjust=-0.5),
    axis.title.y = element_text(size=22,angle=90, vjust=1.2),
    axis.text.x = element_text(colour="black", size=18),
    axis.text.y = element_text(colour="black", size=18), 
    strip.text = element_text(colour="black", size=18))

theme_set(this_theme)



ds2<-read.csv("Data/Equivalent root and C for 5 cm, each plot.csv", header=TRUE)

fake<-tibble(trt = c("CC", "PF", "P"), plot = c("12", "32", "13"), depth = c("105", "105", "105"),
                    root = c(NA, NA, NA), rootC = c(.0001, .0001, .0001), carbon = c(NA, NA, NA))
ds2<-rbind(ds2, fake)

ds2<-ds2%>%
  select(-plot)%>%
  mutate(depth = ifelse((depth == 2.5), 0,
                        ifelse((depth == 10.0), 10,
                               ifelse((depth == 22.5), 20,
                                      ifelse((depth == 45.0), 45,
                                            ifelse((depth == 80.0), 80, 105))))))%>%
  group_by(trt, depth)%>%
  summarise_each(funs(mean(., na.rm = TRUE), std.error(., na.rm = TRUE)))

    
  ds2_depths_possible <- expand.grid(
    depth            = seq(from=min(ds2$depth), max(105), by=5), #Decide resolution here.
    trt              = c("CC", "P", "PF"),
    stringsAsFactors = FALSE
  )

ds2_intpolated <- ds2 %>% 
  right_join(ds2_depths_possible, by=c("trt", "depth")) %>% #Incorporate locations to interpolate
  group_by(trt)%>%
  mutate(
    rootC_interpolated     = spline(x=depth, y=rootC_mean  , xout=depth,  method="natural")$y,
    carbon_interpolated   = spline(x=depth, y=carbon_mean, xout=depth,  method="natural")$y
  ) %>% 
  ungroup()

#ds2_intpolated_rev <- within(ds2_intpolated, depth <- ordered(depth, levels = rev(sort(unique(depth)))))

cc<-ds2_intpolated%>%filter(trt == "CC")
pf<-ds2_intpolated%>%filter(trt == "PF")
p<-ds2_intpolated%>%filter(trt == "P")

cobsmean<-ds2_intpolated%>%
  group_by(depth)%>%
  summarise(avgC = mean(carbon_interpolated))%>%
  full_join(ds2_intpolated, by = "depth")
  #gather(key=variable, value=value, c(avgC, rootC, carbon, rootC_interpolated, carbon_interpolated))%>%

#propfig <- within(propfig, depth <- ordered(depth, levels = rev(sort(unique(depth)))))
#cc <- within(cc, depth <- ordered(depth, levels = rev(sort(unique(depth)))))


rootsCC<-ggplot(cc, aes(x=depth, y=rootC_interpolated)) +
  geom_line(color="#E06100", size=1.2) +
  scale_x_reverse(limits = c(100, -3))+
  #geom_point(shape=1) +
  geom_point(aes(y=rootC_mean), size=4, alpha=1, color="#E06100", na.rm=T) +
  geom_errorbar(aes(ymin=rootC_mean - rootC_std.error, ymax=rootC_mean + rootC_std.error))+
  annotate("text", x=0, y=0.02, label="b", size=12)+
  coord_flip()+
  theme(axis.line = element_line(),
        axis.title.x = element_blank(),
        axis.title.y = element_blank(),
        axis.text.x = element_text(colour="black", size=22),
        axis.text.y = element_blank())

rootsP<-ggplot(p, aes(x=depth, y=rootC_interpolated, color=trt, group=trt)) +
  geom_line(color="#24019B", size=1.2) +
  scale_x_reverse(limits = c(100, -3))+
  #geom_point(shape=1) +
  geom_point(aes(y=rootC_mean), size=4.1, alpha=1, color="#24019B", na.rm=T) +
  geom_errorbar(aes(ymin=rootC_mean - rootC_std.error, ymax=rootC_mean + rootC_std.error), color="black")+
  annotate("text", x=0, y=0.2, label="d", size=12)+
  coord_flip()+
  theme(axis.line = element_line(),
        axis.title.x = element_blank(),
        axis.title.y = element_blank(),
        axis.text.x = element_text(colour="black", size=22),
        axis.text.y = element_blank())

rootsPF<-ggplot(pf, aes(x=depth, y=rootC_interpolated, color=trt, group=trt)) +
  geom_line(color="#83304C", size=1.2) +
  scale_x_reverse(limits = c(100, -3))+
  scale_y_continuous(breaks = c(.1,.3,.5))+
  #geom_point(shape=1) +
  geom_point(aes(y=rootC_mean), size=4, alpha=1, color="#83304C", na.rm=T) +
  geom_errorbar(aes(ymin=rootC_mean - rootC_std.error, ymax=rootC_mean + rootC_std.error), color="black")+
  annotate("text", x=0, y=0.1, label="c", size=12)+
  coord_flip()+
  theme(axis.line = element_line(),
        axis.title.x = element_blank(),
        axis.title.y = element_blank(),
        axis.text.x = element_text(colour="black", size=22),
        axis.text.y = element_blank())

desert<-c("#E06100", "#24019B", "#83304C")
carbon<-ggplot(cobsmean, aes(x=depth, y=avgC)) +
  #geom_point(shape=1) +
  geom_point(aes(y=carbon_mean, shape=trt, color=trt), size=4, alpha=1, na.rm=T) +
  scale_x_reverse(limits = c(100, -3))+
  geom_errorbar(aes(ymin=carbon_mean - carbon_std.error, ymax=carbon_mean + carbon_std.error ), alpha=.4)+
  geom_line(size=1.2) +
  annotate("text", x=0, y=5, label="a", size=12)+
  scale_color_manual(values = desert, breaks=c("CC", "PF", "P"), labels=c("Maize", "Fertilized Prairie", "Prairie"))+
  scale_shape_manual(values = c(15, 17, 19), breaks=c("CC", "PF", "P"), labels=c("Maize", "Fertilized Prairie", "Prairie"))+
  coord_flip()+
  theme(axis.line = element_line(),
        legend.position=c(.62, .35), legend.title=element_blank(),
        legend.text = element_text(size=14), legend.key.size=unit(.8, "cm"),
        axis.title.x = element_blank(),
        axis.title.y = element_blank(),
        axis.text.x = element_text(colour="black", size=22),
        axis.text.y = element_text(colour="black", size=22))
  
###Table 3, is this you? Yes. It is.
sumprops<-ds2_intpolated%>%
  group_by(trt)%>%
  mutate(totalrootC = sum(rootC_interpolated), 
         totalcarbon = sum(carbon_interpolated))%>%
  mutate(proprootC = rootC_interpolated/totalrootC,
         propcarbon = carbon_interpolated/totalcarbon)


  ggplot(sumprops, aes(x=-depth, y=proprootC)) +
 geom_line(color="green", size=1.2) +
 geom_line(aes(y=propcarbon), color="brown", size=1.2) +
 coord_flip()+
  facet_wrap(~trt)
  
split<-sumprops%>%
  mutate(place = ifelse((depth %in% c(0:20)), "top", "bottom"))%>%
  group_by(trt, place)%>%
  summarise(splitC = sum(carbon_interpolated), splitR = sum(rootC_interpolated))%>%
  group_by(trt)%>%
  mutate(totalrootC = sum(splitR), 
         totalcarbon = sum(splitC))%>%
  mutate(proprootC = splitR/totalrootC,
         propcarbon = splitC/totalcarbon)

knitr::kable(split, digits = 2, caption = "Above vs below 20 cm")
  
 

#rootCs
#Measured values were:
#  4  2013     CC  1.953566  1953.566
#5  2013      P 10.148968 10148.968
#6  2013     PF  5.841929  5841.929

#Modeled values were:
#  trt totalrootC totalcarbon
#(chr)     (dbl)       (dbl)
#1    CC  1.884839    160.4608
#2     P 10.397572    162.5389
#3    PF  5.594652    183.6342
  
  library(grid)
  library(gridExtra) #Don't remember if this one is necessary
  
  vplayout<- function(x,y)
    viewport(layout.pos.row=x, layout.pos.col=y)
  
  pdf("Figures/Roots and Soil 2013 Profile.pdf", width = 12, height = 8, family = "Times")
  grid.newpage()
  
  #This sets up the "grid".  This one is 4 rows and 3 columns. 
  #The last row and the first column are tiny because they are axis labels
  pushViewport(viewport(layout = grid.layout(2,5, heights = unit(c(5, 0.4), "null"), 
                                             widths = unit(c(0.4, 5.75, 5,5,5), "null"))))
  
  #This is a label that spans row 1 through 3 (1:3)
  grid.text((expression(paste("Depth (cm)"))), rot = 90, vp = viewport(layout.pos.row = 1, layout.pos.col = 1), gp=gpar(fontsize=18))
  
  #This a label that is centered under columns 2:3 
  grid.text("Carbon (Mg/ha)", vp = viewport(layout.pos.row = 2, layout.pos.col = 2:5), gp=gpar(fontsize=18))
  
  #Then I print the figures I made.  The first one is row 1, column 2 and so on.  
  print(carbon, vp = vplayout(1,2))
  print(rootsCC, vp = vplayout (1,3))
  print(rootsPF, vp = vplayout (1,4))
  print(rootsP, vp = vplayout (1,5))
  dev.off()
  
  
  dodge <- position_dodge(width=.9)
  ds2_intpolated <- within(ds2_intpolated, depth <- ordered(depth, levels = rev(sort(unique(depth)))))
  
  pdf("Figures/Roots and Soil 2013 Absolute Differences.pdf", width = 5, height = 8, family = "Times") 
  ggplot(ds2_intpolated, aes(x=depth, y = rootC_interpolated, fill=trt)) + 
    geom_bar(stat = "identity", position = "dodge") +
    #geom_errorbar(aes(ymax = poxconc + poxconcse, ymin=poxconc - poxconcse), position = dodge, width=0.25) +
    scale_x_reverse(limits = c(100, -3))+
    coord_flip()+
    scale_fill_manual(values = desert, breaks=c("CC", "PF", "P"), labels=c("Maize", "Fertilized Prairie", "Prairie"))+
    guides(col = guide_legend(reverse = FALSE))+
    labs(y = (expression(paste("Root Carbon (Mg ha" ^ "-1",")"))),x = "Depth (cm)")+
    theme(#panel.grid.major = element_blank(),
          panel.grid.minor = element_blank(),
          panel.background = element_blank(),
          axis.line = element_line(),
          legend.position=c(.65,.35), legend.title=element_blank(), 
          legend.key.size=unit(.75, "cm"), legend.text = element_text(size=18),
          axis.title.x = element_text(size=20),
          axis.title.y = element_text(size=20,angle=90),
          axis.text.x = element_text(colour="black", size=20),
          axis.text.y = element_text(colour="black", size=20))
  dev.off()
