library(shiny)
library(dplyr)
library(ggplot2)
library(scales)
library(ggcorrplot)
library(treemapify)

# Helper functions
winsorize <- function(x, trim_pct = 1) {
  if (is.null(x) || length(x) == 0) return(x)
  if (!is.numeric(x)) return(x)
  if (trim_pct <= 0) return(x)
  low_q <- trim_pct/100
  high_q <- 1 - low_q
  qlow <- quantile(x, probs = low_q, na.rm = TRUE)
  qhigh <- quantile(x, probs = high_q, na.rm = TRUE)
  x[x < qlow] <- qlow
  x[x > qhigh] <- qhigh
  x
}

apply_transform_and_trim <- function(vec, log_transform = FALSE, trim_pct = 0) {
  v <- as.numeric(vec)
  v[is.infinite(v)] <- NA
  if (log_transform) v <- log1p(v)
  if (!is.numeric(v)) return(v)
  if (!is.null(trim_pct) && trim_pct > 0 && trim_pct < 50) {
    low_q  <- trim_pct / 100
    high_q <- 1 - low_q
    qlow  <- quantile(v, probs = low_q, na.rm = TRUE)
    qhigh <- quantile(v, probs = high_q, na.rm = TRUE)
    v[v < qlow]  <- qlow
    v[v > qhigh] <- qhigh
  }
  v
}

if (!exists("netWorkDataset_clean")) stop("Please load your dataset 'netWorkDataset_clean' before running the app.")

all_attacks <- unique(netWorkDataset_clean$class)

attack_groups <- data.frame(class = all_attacks, stringsAsFactors = FALSE)
for(i in 1:nrow(attack_groups)) {
  cls <- attack_groups$class[i]
  if (cls == "normal.") {
    attack_groups$group[i] <- "Normal"
  } else if (cls %in% c("neptune.", "smurf.", "teardrop.")) {
    attack_groups$group[i] <- "DoS"
  } else if (cls %in% c("satan.", "ipsweep.", "portsweep.", "nmap.")) {
    attack_groups$group[i] <- "Probe"
  } else if (cls %in% c("warezclient.", "guess_passwd.", "ftp_write.", "imap.")) {
    attack_groups$group[i] <- "R2L"
  } else if (cls %in% c("buffer_overflow.", "loadmodule.", "perl.", "rootkit.")) {
    attack_groups$group[i] <- "U2R"
  } else {
    attack_groups$group[i] <- "Others"
  }
}

netWorkDataset_all <- merge(netWorkDataset_clean, attack_groups, by = "class")
netWorkDataset_all$class <- factor(netWorkDataset_all$class, levels = all_attacks)
netWorkDataset_all$group <- factor(netWorkDataset_all$group, levels = c("Normal", "DoS", "Probe", "R2L", "U2R", "Others"))

colors_12 <- c(
  "normal."       = "#aec7e8",
  "neptune."      = "#FF7300",
  "satan."        = "#008229",
  "ipsweep."      = "#FF0000",
  "portsweep."    = "#6C009E",
  "smurf."        = "#9E4C00",
  "nmap."         = "#00FBFF",
  "back."         = "#7f7f7f",
  "teardrop."     = "#00FF22",
  "warezclient."  = "#FF00E9",
  "pod."          = "#0018FF",
  "guess_passwd." = "#ffbb78"
)

group_colors <- c(
  "Normal" = "#aec7e8",
  "DoS" = "#FF7300",
  "Probe" = "#008229",
  "R2L" = "#FF00E9",
  "U2R" = "#FF00FF",
  "Others" = "#888888"
)

numeric_vars <- c(
  "duration","src_bytes","dst_bytes","count","srv_count",
  "serror_rate","srv_serror_rate","rerror_rate","srv_rerror_rate",
  "dst_host_count","dst_host_srv_count","dst_host_same_srv_rate",
  "dst_host_diff_srv_rate","dst_host_same_src_port_rate"
)

numeric_vars <- numeric_vars[numeric_vars %in% names(netWorkDataset_all)]

ui <- fluidPage(
  titlePanel("KDD Cup 1999 - Visualizations with PCA"),
  sidebarLayout(
    sidebarPanel(
      width = 3,
      h4("Controls"),
      checkboxGroupInput("classes", "Select Classes:", choices = sort(unique(netWorkDataset_all$class)),
                         selected = unique(netWorkDataset_all$class)),
      
      selectInput("numvar", "Numeric Variable:", choices = numeric_vars, selected = "src_bytes"),
      checkboxInput("log_transform", "Apply log1p transform to all plots?", value = TRUE),
      sliderInput("trim_pct", "Winsorize (% per tail)", min = 0, max = 10, value = 1, step = 0.5),
      sliderInput("sample_n", "Max sample size (0 = no sampling):", min = 1000, max = 1e6, value = 50000, step = 1000)
    ),
    mainPanel(
      width = 9,
      tabsetPanel(
        id = "tabs",
        tabPanel("ECDF", plotOutput("ecdfPlot", height = "600px")),
        tabPanel("Violin", plotOutput("violinPlot", height = "700px")),
        tabPanel("Stacked Bars", plotOutput("stackedBar", height = "600px")),
        tabPanel("Scatter", plotOutput("scatterPlot", height = "650px")),
        tabPanel("Correlation", plotOutput("corrPlot", height = "700px")),
        tabPanel("Histograms", plotOutput("histPlot", height = "600px")),
        tabPanel("Boxplots", plotOutput("boxPlot", height = "700px")),
        tabPanel("Treemap", plotOutput("treemapPlot", height = "700px")),
        tabPanel("PCA", plotOutput("pcaPlot", height = "600px"))
      )
    )
  )
)

server <- function(input, output, session) {
  
  df_filtered <- reactive({
    req(input$classes)
    subset(netWorkDataset_all, class %in% input$classes)
  })
  
  df_trans <- reactive({
    df <- df_filtered()
    for (v in numeric_vars) {
      df[[v]] <- apply_transform_and_trim(df[[v]], input$log_transform, input$trim_pct)
    }
    df
  })
  
  sample_df <- function(df, n) {
    if (is.null(n) || n <= 0) return(df)
    if (n >= nrow(df)) return(df)
    set.seed(123)
    df[sample(seq_len(nrow(df)), n), , drop = FALSE]
  }
  
  output$ecdfPlot <- renderPlot({
    var <- input$numvar
    df <- df_trans()
    df <- df[!is.na(df[[var]]), ]
    dfp <- if (input$sample_n > 0) sample_df(df, min(nrow(df), input$sample_n)) else df
    
    ggplot(dfp, aes_string(x = var, color = "group")) +
      stat_ecdf(size = 1) +
      scale_x_continuous(labels = scales::comma) +
      labs(title = paste("ECDF -", var), x = var, y = "ECDF", color = "Group") +
      theme_minimal(base_size = 13)
  }, res = 96)
  
  output$violinPlot <- renderPlot({
    var <- input$numvar
    df <- df_trans()
    df <- df[!is.na(df[[var]]), ]
    df <- df[, c("class", "group", var)]
    names(df)[3] <- "var"
    
    med <- aggregate(var ~ class, data = df, FUN = median)
    med <- med[order(med$var), ]
    df$class <- factor(df$class, levels = med$class)
    
    ggplot(df, aes(x = class, y = var, fill = group)) +
      geom_violin(scale = "width", trim = FALSE, alpha = 0.7) +
      geom_boxplot(width = 0.08, outlier.size = 0.6, alpha = 0.9) +
      coord_flip() +
      scale_y_continuous(labels = scales::comma) +
      scale_fill_manual(values = group_colors) +
      labs(title = paste("Violin + Boxplot -", var), x = "Class", y = var, fill = "Group") +
      theme_minimal(base_size = 12)
  }, res = 96)
  
  output$stackedBar <- renderPlot({
    df <- df_filtered()
    
    counts_df <- as.data.frame(table(df$group, df$class))
    names(counts_df) <- c("group", "class", "count")
    
    counts_df$group <- factor(as.character(counts_df$group), levels = levels(netWorkDataset_all$group))
    counts_df$class <- factor(as.character(counts_df$class), levels = levels(netWorkDataset_all$class))
    
    total_per_group <- tapply(counts_df$count, counts_df$group, sum)
    counts_df$proportion <- counts_df$count / total_per_group[as.character(counts_df$group)]
    
    ggplot(counts_df, aes(x = group, y = proportion, fill = class)) +
      geom_bar(stat = "identity", position = "fill") +
      scale_y_continuous(labels = scales::percent_format()) +
      labs(title = "Class Proportion Within Each Group", x = "Group", y = "Proportion", fill = "Class") +
      theme_minimal(base_size = 13) +
      theme(axis.text.x = element_text(angle = 35, hjust = 1))
  })
  
  output$scatterPlot <- renderPlot({
    df <- df_trans()
    df <- df[df$class %in% input$classes, ]
    
    df$xvar <- apply_transform_and_trim(df$src_bytes, input$log_transform, input$trim_pct)
    df$yvar <- apply_transform_and_trim(df$dst_bytes, input$log_transform, input$trim_pct)
    df$sizevar <- apply_transform_and_trim(df$duration, FALSE, 0)
    df <- df[!is.na(df$xvar) & !is.na(df$yvar), ]
    
    n <- nrow(df)
    if (input$sample_n > 0 && n > input$sample_n) {
      set.seed(123)
      df <- df[sample(seq_len(n), input$sample_n), ]
    }
    
    ggplot(df, aes(x = xvar, y = yvar, color = class, size = sizevar)) +
      geom_point(alpha = 0.6) +
      scale_color_manual(values = colors_12) +
      scale_size_continuous(range = c(1, 8)) +
      labs(title = "Scatter: src_bytes vs dst_bytes", x = "src_bytes", y = "dst_bytes", color = "Class", size = "Duration") +
      theme_minimal(base_size = 14) +
      guides(color = guide_legend(override.aes = list(shape = 15, size = 5)))
  }, res = 96)
  
  output$corrPlot <- renderPlot({
    df <- df_trans()
    df_num <- df[, numeric_vars]
    df_num <- df_num[sapply(df_num, is.numeric)]
    corr <- cor(df_num, use = "pairwise.complete.obs", method = "spearman")
    
    ggcorrplot(corr, hc.order = TRUE, type = "lower", lab = TRUE, lab_size = 3) +
      ggtitle("Spearman Correlation Matrix")
  }, res = 96)
  
  output$histPlot <- renderPlot({
    var <- input$numvar
    df <- df_trans()
    df <- df[!is.na(df[[var]]), ]
    
    ggplot(df, aes_string(x = var, fill = "group", color = "group")) +
      geom_histogram(bins = 60, position = "identity", alpha = 0.45) +
      scale_fill_manual(values = group_colors) +
      scale_color_manual(values = group_colors) +
      labs(title = paste("Histogram of", var), x = var, y = "Frequency") +
      theme_minimal(base_size = 13)
  }, res = 96)
  
  output$boxPlot <- renderPlot({
    var <- input$numvar
    df <- df_trans()
    df <- df[!is.na(df[[var]]), ]
    
    lower <- quantile(df[[var]], probs = 0.01, na.rm = TRUE)
    upper <- quantile(df[[var]], probs = 0.99, na.rm = TRUE)
    
    ggplot(df, aes_string(x = "group", y = var, fill = "group")) +
      geom_boxplot(outlier.size = 0.6, alpha = 0.9) +
      coord_flip(ylim = c(lower, upper)) +
      scale_fill_manual(values = group_colors) +
      labs(title = paste("Robust Boxplot -", var), x = "Group", y = var) +
      theme_minimal(base_size = 13)
  }, res = 96)
  
  output$treemapPlot <- renderPlot({
    summary_group <- aggregate(count ~ group, data = netWorkDataset_all, FUN = length)
    names(summary_group)[2] <- "count"
    
    ggplot(summary_group, aes(area = count, fill = group, label = paste0(group, "\n", count))) +
      geom_treemap() +
      geom_treemap_text(color = "white", place = "centre", grow = TRUE, reflow = TRUE) +
      scale_fill_manual(values = group_colors) +
      labs(title = "Treemap - Attack Groups Counts") +
      theme(legend.position = "none")
  }, res = 96)
  
  output$pcaPlot <- renderPlot({
    df <- df_filtered()
    
    for (v in numeric_vars) {
      df[[v]] <- apply_transform_and_trim(df[[v]], input$log_transform, input$trim_pct)
    }
    
    df_num <- df[, numeric_vars]
    df_num <- df_num[complete.cases(df_num), ]
    
    if (nrow(df_num) == 0) {
      plot.new()
      text(0.5, 0.5, "No valid data for PCA", cex = 1.5)
      return()
    }
    
    if (input$sample_n > 0 && nrow(df_num) > input$sample_n) {
      set.seed(123)
      sample_rows <- sample(seq_len(nrow(df_num)), input$sample_n)
      df_num <- df_num[sample_rows, ]
      df <- df[sample_rows, ]
    }
    
    vars_sd <- apply(df_num, 2, sd)
    if (any(vars_sd == 0)) {
      df_num <- df_num[, vars_sd > 0]
    }
    
    pca <- prcomp(df_num, center = TRUE, scale. = TRUE)
    
    scores <- as.data.frame(pca$x)
    scores$group <- df$group
    
    ggplot(scores, aes(x = PC1, y = PC2, color = group)) +
      geom_point(alpha = 0.7) +
      scale_color_manual(values = group_colors) +
      labs(title = "PCA: Principal Components 1 & 2", x = "PC1", y = "PC2", color = "Group") +
      theme_minimal(base_size = 14)
  }, res = 96)
  
}

shinyApp(ui, server)
