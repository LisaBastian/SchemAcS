#load packages
library("dplyr")
library('ggplot2')
library('readr')
library('forcats')
library('emmeans')
library("effectsize")
library(gghalves)
library(afex)

#DEFINE
baseDir =  "/Volumes/T7/01_SchemAcS/05_Analysis"

source(paste0(baseDir,"/Performance_Logs/SelectiveLog/s1-s5/scripts/function_lib.R"))


###################### plot accuracy across sessions ###########################
#load data
df <- read.csv.csv(paste0(baseDir,"/Performance_Logs/SelectiveLog/built-up_dfs/base_obj_acc.csv"))

# 1) collapse across categories at the participant level:
#    compute, for each ID x phase x condition x session, the mean accuracy
id_means <- df %>%
  group_by(ID, Condition, Session) %>%
  summarise(acc_id_mean = mean(obj_accuracy, na.rm = TRUE), .groups = "drop")

# 2) group summary across IDs: mean and SE (SE across IDs)
summary_by_group <- id_means %>%
  group_by(Condition, Session) %>%
  summarise(
    mean_acc = mean(acc_id_mean, na.rm = TRUE),
    se_acc   = sd(acc_id_mean, na.rm = TRUE) / sqrt(dplyr::n()),
    n_ids    = dplyr::n(),
    .groups  = "drop"
  )


p_sess <- plot_line_se(
  data = summary_by_group,
  x_var = "Session",
  y_var = "mean_acc",
  se_var = "se_acc",
  group_var = "Condition",
  facet_var = NULL,        # if you want separate panels
  y_label = "Accuracy (%)",
  hline = 50,
  y_limits = c(45, 100),
  save_path = paste0(baseDir,'/Performance_Logs/SelectiveLog/s1-s5/plots'),
  filename = "object_accuracy_by_session.pdf",
  width = 6,
  height = 4.5
)

print(p_sess)

# 3) plot: separate panels for phases, means with SE error bars
p <- ggplot(summary_by_group,
            aes(x = sessions, y = mean_acc, color = conditions, group = conditions)) +
  geom_line(position = position_dodge(width = 0.2), linewidth = 0.8) +
  geom_point(position = position_dodge(width = 0.2), size = 3) +
  geom_errorbar(
    aes(ymin = mean_acc - se_acc, ymax = mean_acc + se_acc),
    width = 0.2,
    position = position_dodge(width = 0.2),
    linewidth = 0.4
  ) +
  geom_hline(yintercept = 50,
             linetype = "dashed",
             color = "black",
             linewidth = 0.6) +
  ylim(c(40,100))+
  scale_color_manual(
    values = c(
      "control" = "#707071",
      "sleep"   = "#313f99",
      "wake"    = "#dc1e32"
    )
  ) +
  labs(
    x = "Session",
    y = "Accuracy (%)",
    color = "Condition"
  ) +
  theme_classic(base_size = 14) +
  theme(
    axis.title = element_text(size = 12),
    axis.text  = element_text(size = 12, color = 'black'),
    legend.position = 'top',
    legend.title    = element_blank(),
    axis.line = element_line(linewidth = 0.4)  # thinner axes
  ) 

print(p)

#save plot 
ggsave(
  filename = "object_accuracy_by_session_condition_retrieve.pdf",  # output filename
  plot = p,                                      # the ggplot object
  path = paste0(baseDir,'/Performance_Logs/SelectiveLog/s1-s5/plots'),                                # optional: choose a directory
  width = 3,                                     # width in inches
  height = 3,                                    # height in inches
  units = "in",                                  # specify units (in, cm, or mm)
  dpi = 300,                                     # resolution (useful if exporting to raster formats)
)

#################### test session* condition interaction #######################

model_obj <- aov(obj_accuracy ~ conditions*sessions+Gender+Error(IDs/sessions),  data = df_merged) 
summary(model_obj) #session effect
eta_squared(model_obj, partial = TRUE)
emm_sess = pairs(emmeans(model_obj, ~'sessions'), infer = TRUE) #session 1 is worse than all others! p = 0.0002 : 0.02

emm_gen = pairs(emmeans(model_obj, ~'Gender'), infer = TRUE)

model_rm <- aov_ez(
  id = "IDs",
  dv = "obj_accuracy",
  within = "sessions",
  between = c("conditions", "Gender"),  # if conditions is between
  data = df_merged
)

emm <- emmeans(model_rm, ~ sessions)
pairs_res <- pairs(emm)
summary_pairs <- summary(pairs_res)


