require("ggplot2")
require("dplyr")

data <- read.csv("/Users/bouchard/w/ptanalysis/results/all/2021-02-02-21-53-48-ITF5aH9i.exec/snrs.csv")



snrs <- ggplot(data %>% filter(parameter > 0.0, coord == "gradient_0", type == "SKL" | type == "Rejection"), # NaNs at zero 
  aes(x = parameter, y = SNR, colour = factor(type))) + 
  guides(colour=guide_legend(title="Objective function")) +
  ylab("SNR of the gradient |mean/std. dev.|") + 
  xlab("Variational parameter") + 
  geom_line() + 
  theme_bw() + 
  theme(legend.position = c(0.8, 0.5))

ggsave(filename = "/Users/bouchard/w/ptanalysis/snrs.pdf", snrs, width = 4, height = 3)



values <- ggplot(data %>% filter(coord == "objective"), 
  aes(x = parameter, y = mean, colour = factor(type))) + 
  guides(colour=guide_legend(title="Objective function")) +
  ylab("Value of the objective function") + 
  xlab("Variational parameter") + 
  geom_line()  + 
  theme_bw() +
  theme(legend.position = c(0.2, 0.7))

ggsave(filename = "/Users/bouchard/w/ptanalysis/objectives.pdf", values, width = 4, height = 3)