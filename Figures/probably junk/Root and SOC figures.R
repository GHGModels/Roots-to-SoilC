
setwd("C:/Users/rdietzel/Dropbox/Root manuscript/Figures and analysis")

library(tidyr)
library(dplyr)
library(ggplot2)


propfig<-read.csv("Roots and Soil C.csv", header=TRUE)

roots<-propfig%>%
  gather(key = variable, value = value, soilCprop:CN)%>%
  within(depth <- ordered(depth, levels = rev(sort(unique(depth)))))

  
theme_set(yf_theme)
ggplot() +
   geom_point(aes(x=factor(depth), y=value), size=4, 
            data=filter(roots, variable=="rootCprop"), color="green")+
   geom_point(aes(x=factor(depth), y=value), size=4, 
             data=filter(roots, variable=="soilCprop"), color="brown")+
   facet_wrap(~trt)+
   coord_flip()
 



