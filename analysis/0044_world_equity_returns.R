cat("\014") # Clear your console
rm(list = ls()) #clear your environment

########################## Load in header file ######################## #
setwd("~/git/of_dollars_and_data")
source(file.path(paste0(getwd(),"/header.R")))

########################## Load in Libraries ########################## #


########################## Start Program Here ######################### #

library(ggplot2)
library(scales)
library(grid)
library(gridExtra)
library(gtable)
library(RColorBrewer)
library(stringr)
library(ggrepel)
library(lubridate)
library(ggjoy)
library(tidyr)
library(dplyr)

folder_name <- "0044_world_equities"
out_path <- paste0(exportdir, folder_name)
dir.create(file.path(paste0(out_path)), showWarnings = FALSE)

# ############################  End  ################################## #

non_us   <- readRDS(paste0(localdir, "0044_ms_non_us_equity.Rds"))

sp500_ret_pe <- readRDS(paste0(localdir, "0009_sp500_ret_pe.Rds")) %>%
                  mutate(
                    ret_cpi = cpi/lag(cpi) - 1)

min_date <- max(min(non_us$date), min(sp500_ret_pe$date))
max_date <- min(max(non_us$date), max(sp500_ret_pe$date))

# Filter the US data
us_filtered <- sp500_ret_pe %>%
                filter(date >= (min_date - 32), date <= max_date) %>%
                mutate(`U.S.` = price_plus_div/lag(price_plus_div) - 1,
                       month = month(date),
                       year = year(date)) %>%
                select(month, year, `U.S.`, ret_cpi)

# Join the US and non-US data
wide_ret <- non_us %>%
            mutate(month = month(date),
                   year = year(date)) %>%
            filter(date >= min_date, date <= max_date) %>%
            inner_join(us_filtered) %>%
            select(-month, -year) %>%
            mutate(`U.K.` = `U.K.` - ret_cpi,
                   France = France - ret_cpi,
                   Italy = Italy - ret_cpi,
                   Russia = Russia - ret_cpi,
                   Spain = Spain - ret_cpi,
                   Germany = Germany - ret_cpi) %>%
            select(-ret_cpi)

all_ret <- gather(wide_ret, key=key, value=value, -date) %>%
            filter(!is.na(value))

# Create indexed for later line chart
for (i in 1:nrow(all_ret)){
  if(i == 1){
    all_ret[i, "index"] <- 100
  } else if (all_ret[i, "key"] != all_ret[(i-1), "key"]){
    all_ret[i, "index"] <- 100
  } else {
    all_ret[i, "index"] <- all_ret[(i-1), "index"] * (1 + all_ret[(i-1), "value"])
  }
}

to_plot <- all_ret

  #Create Joyplot
  file_path <- paste0(exportdir, "0044_world_equities/joyplot_equities.jpeg")
  
  plot <- ggplot(data = to_plot, aes(x=value, y=factor(key), fill = factor(key))) +
    geom_joy_gradient(rel_min_height = 0.01, scale = 3) +
    scale_fill_discrete(guide = FALSE) +
    scale_x_continuous(label = percent, limits = c(-0.35, 0.35)) +
    of_dollars_and_data_theme +
    ggtitle(paste0("You Can Also See This When\nComparing Their Return Distributions")) +
    labs(x = paste0("1-Month Real Return (%)" ), y = "Equity Market")
  
  # Add a source and note string for the plots
  source_string <- paste0("Source:  Shiller Data, Morningstar (OfDollarsAndData.com)")
  note_string   <- paste0("Note:  Returns are adjusted for dividends and inflation in USD terms.") 
  
  # Turn plot into a gtable for adding text grobs
  my_gtable   <- ggplot_gtable(ggplot_build(plot))
  
  # Make the source and note text grobs
  source_grob <- textGrob(source_string, x = (unit(0.5, "strwidth", source_string) + unit(0.2, "inches")), y = unit(0.1, "inches"),
                          gp =gpar(fontfamily = "my_font", fontsize = 8))
  note_grob   <- textGrob(note_string, x = (unit(0.5, "strwidth", note_string) + unit(0.2, "inches")), y = unit(0.15, "inches"),
                          gp =gpar(fontfamily = "my_font", fontsize = 8))
  
  # Add the text grobs to the bototm of the gtable
  my_gtable   <- arrangeGrob(my_gtable, bottom = source_grob)
  my_gtable   <- arrangeGrob(my_gtable, bottom = note_grob)
  
  # Save the gtable
  ggsave(file_path, my_gtable, width = 15, height = 12, units = "cm")
  
## Create indexed line chart
  file_path <- paste0(exportdir, "0044_world_equities/equity_lines.jpeg")
  
  to_plot <- filter(all_ret, key != "Russia")
  
  plot <- ggplot(data = to_plot, aes(x=date, y=index, col = factor(key))) +
    geom_line() +
    scale_color_discrete(guide = FALSE) +
    geom_text_repel(data = filter(to_plot, date == max(to_plot$date), !(key %in% c("Germany", "France", "U.K.", "Spain"))), 
                    aes(x = date, 
                        y = index, 
                        col = as.factor(key), 
                        label = as.character(key),
                        family = "my_font"
                    ), force = 2,
                    max.iter=3000) +
    geom_text_repel(data = filter(to_plot, date == max(to_plot$date), key %in% c("Spain")), 
                    aes(x = date, 
                        y = index, 
                        col = as.factor(key), 
                        label = as.character(key),
                        family = "my_font"
                    ), force = 2,
                    max.iter=3000,
                    nudge_y = 300,
                    segment.color = 'transparent') +
    geom_text_repel(data = filter(to_plot, date == "2005-01-01", key %in% c("U.K.")), 
                    aes(x = date, 
                        y = index, 
                        col = as.factor(key), 
                        label = as.character(key),
                        family = "my_font"
                    ), force = 2,
                    max.iter=3000,
                    nudge_y = 280,
                    segment.color = 'transparent') +
    geom_text_repel(data = filter(to_plot, date == "2011-07-01", key %in% c("France")), 
                    aes(x = date, 
                        y = index, 
                        col = as.factor(key), 
                        label = as.character(key),
                        family = "my_font"
                    ), force = 2,
                    max.iter=3000,
                    nudge_y = 100,
                    segment.color = 'transparent') +
    geom_text_repel(data = filter(to_plot, date == "1993-05-01", key %in% c("Germany")), 
                    aes(x = date, 
                        y = index, 
                        col = as.factor(key), 
                        label = as.character(key),
                        family = "my_font"
                    ), force = 2,
                    max.iter=3000,
                    nudge_y = 400,
                    segment.color = 'transparent') +
    scale_x_date() +
    of_dollars_and_data_theme +
    ggtitle(paste0("Equity Markets Around the World\nExhibit Varied Outcomes")) +
    labs(x = paste0("Date"), y = "Index (Start = 100)")
  
  # Turn plot into a gtable for adding text grobs
  my_gtable   <- ggplot_gtable(ggplot_build(plot))
  
  # Make the source and note text grobs
  source_grob <- textGrob(source_string, x = (unit(0.5, "strwidth", source_string) + unit(0.2, "inches")), y = unit(0.1, "inches"),
                          gp =gpar(fontfamily = "my_font", fontsize = 8))
  note_grob   <- textGrob(note_string, x = (unit(0.5, "strwidth", note_string) + unit(0.2, "inches")), y = unit(0.15, "inches"),
                          gp =gpar(fontfamily = "my_font", fontsize = 8))
  
  # Add the text grobs to the bototm of the gtable
  my_gtable   <- arrangeGrob(my_gtable, bottom = source_grob)
  my_gtable   <- arrangeGrob(my_gtable, bottom = note_grob)
  
  # Save the gtable
  ggsave(file_path, my_gtable, width = 15, height = 12, units = "cm")  
