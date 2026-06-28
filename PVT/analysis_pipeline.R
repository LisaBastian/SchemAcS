library(dplyr)
library(tidyr)
library(ggplot2)
library(emmeans)

#DEFINE
rootDir = '/Volumes/T7/01_SchemAcS/05_Analysis/PVT' 

#functions
se <- function(x){sd(x, na.rm = TRUE)/sqrt(length(!is.na(x)))}

#load data
PVT_df_sleep   <- read.csv(paste0(rootDir,"/results/PVT_df_sleep.csv"))
PVT_df_control <- read.csv(paste0(rootDir,"/results/PVT_df_Kontrolle.csv"))
PVT_df_wake <- read.csv(paste0(rootDir,"/results/PVT_df_wake.csv"))


########################### TEST DIFFERENCES IN RT #############################

#are the two groups different cross the sessions? 
PVT_df <- rbind(PVT_df_sleep,PVT_df_control,PVT_df_wake)
PVT_df$condition <- c(rep("sleep",nrow(PVT_df_sleep)),rep("control",nrow(PVT_df_control)),rep("wake",nrow(PVT_df_wake)))
PVT_df$sess_cond <- c(paste0(PVT_df$session,"_",PVT_df$condition))

model_PVT <- aov(avg_rt ~ condition*session, data = PVT_df) 
summary(model_PVT) 
pairs(emmeans(model_PVT, ~'condition'), infer = TRUE)


################################## PLOTS #######################################

#plot REACTION TIMES 
sum_rt        <- summarise(group_by(PVT_df, sess_cond), my_mean=mean(avg_rt, na.rm = TRUE),my_se=se(avg_rt))
sum_rt$session   <- sapply(strsplit(sum_rt$sess_cond, "_"), `[`, 1)
sum_rt$condition <- sapply(strsplit(sum_rt$sess_cond, "_"), `[`, 2)

rt_plot <- ggplot(sum_rt,
            aes(x=session, y=my_mean, group=condition, color=condition)) +
  geom_line(position = position_dodge(width = 0.2), linewidth = 0.8) +
  geom_point(position = position_dodge(width = 0.2), size = 3) +
  geom_errorbar(
    aes(ymin = my_mean - my_se, ymax = my_mean + my_se),
    width = 0.15,
    position = position_dodge(width = 0.2),
    linewidth = 0.6
  ) +
  ylim(260,340)+
  scale_color_manual(
    values = c(
      "control" = "darkgrey",
      "sleep"   = "#1f78b4",
      "wake"    = "#e31a1c"
    )
  ) +
  labs(
    x = "Session",
    y = "Reaction time (ms)",
    color = "Condition"
  ) +
  theme_minimal(base_size = 12) +
  theme(
    panel.grid.minor = element_blank(),
    legend.position = "top"
  )

print(rt_plot)

ggsave(paste0(rootDir,"/plots/rt_plot.pdf"), plot = rt_plot, width = 6, height = 4)


#plot WAIT TIMES
sum_wait        <- summarise(group_by(PVT_df, sess_cond), my_mean=mean(avg_wait, na.rm = TRUE),my_se=se(avg_rt))
sum_wait$session   <- sapply(strsplit(sum_data$sess_cond, "_"), `[`, 1)
sum_wait$condition <- sapply(strsplit(sum_data$sess_cond, "_"), `[`, 2)


wait_plot <- ggplot(sum_wait, aes(x=session, y=my_mean, group=condition, color=condition)) + 
  geom_line(size = 1,
            position = position_dodge(width = 0.3))+
  geom_pointrange(aes(ymin=my_mean-my_se, ymax=my_mean+my_se), 
                  size = 1, 
                  linewidth = 1,
                  position = position_dodge(width = 0.3)) +
  labs(x = "Session", y = "Wait time [ms]") +
  ggtitle("PVT Wait Times") +
  theme_classic()+
  theme(axis.text.x = element_text(angle = 0, size = 10, colour = 'black'), 
        axis.text.y = element_text(size = 10, colour = 'black'),
        plot.title = element_text(size=13)) +
  scale_color_manual(values=c('darkgrey','#1f78b4','#e31a1c'))

ggsave(paste0(rootDir,"/plots/wait_plot.pdf"), plot = wait_plot, width = 6, height = 4)



