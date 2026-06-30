with open('analysis.qmd', 'r') as f:
    content = f.read()

new_plot_code = r'''
p_coef <- ggplot(df_coef_plot, aes(x = Wave_Num, y = Coefficient)) +
  geom_line(color = "black", linewidth = 0.8) +
  geom_point(size = 2) +
  geom_errorbar(aes(ymin = Lower, ymax = Upper), width = 0.2) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "red", alpha = 0.6) +
  facet_wrap(~ Group) +
  theme_minimal() +
  scale_x_continuous(breaks = 3:8, labels = paste0("W", 3:8)) +
  labs(
    x = "Study Wave",
    y = "Active Homophily Coefficient (Log-Odds)"
  )
  
ggsave(here("Plots", "fig-active-coefs.png"), p_coef, width = 8, height = 6)
'''

# Identify the old plotting block in analysis.qmd
start_marker = "p_coef <- ggplot"
end_marker = 'ggsave(here("Plots", "fig-active-coefs.png")'

start_idx = content.find(start_marker)
end_idx = content.find(end_marker)
# Find the end of the line
end_line_idx = content.find("\n", end_idx + len(end_marker))

content = content[:start_idx] + new_plot_code + content[end_line_idx:]

with open('analysis.qmd', 'w') as f:
    f.write(content)
