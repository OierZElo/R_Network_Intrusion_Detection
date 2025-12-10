KDD CUP 1999 DATA Analysis Report

📄 Introduction
What is this document?

This document covers the complete workflow followed in the analysis of the KDD CUP 1999 dataset, from loading and cleaning the data to performing transformations, exploratory analysis, and building a web application with the obtained graphs.
Purpose

Its purpose is to explain the reasoning behind each step, provide a clear justification of the selected methods, and summarize the results obtained.
Structure

The structure of this report is as follows:

    Description of the dataset and justification of its choice.

    Data loading process and explanation of the functions used.

    Data cleaning steps, including decisions made and avoided.

    Data transformation and reasons behind each modification.

    Exploratory data analysis, explanation of the produced plots, and conclusions.

    Description of the web application and its interface.

💾 Dataset: Description and Justification
Description

The KDD CUP 1999 dataset is one of the most widely used benchmarks for research in network intrusion detection. Each row in the dataset corresponds to a network connection, labeled either as normal or as a specific type of attack. In total, the original dataset contains 41 different columns, describing traffic statistics, protocol information, content features, and temporal behavior indicators.
Reasons for Choosing this Dataset

    It is a classical and well-known dataset in cybersecurity and machine learning research.

    It offers a mixture of numerical and categorical variables, allowing the demonstration of diverse preprocessing techniques.

    Its high dimensionality and imbalance make it suitable for illustrating real-world data challenges.

    It provides a meaningful context for building a data-driven web application.

📥 Dataset Loading
R Code and Reasoning

The dataset was loaded using the following R commands:
R

csv <- read.csv("kddcup.csv")
netWorkDataset <- as_tibble(csv)

    read.csv() loads the raw file into a data frame.

    as_tibble() improves readability and printing behavior, which is especially beneficial when working with large datasets.

Column Name Extraction

The column names were extracted from a separate file. This involved reading the file line by line and applying string processing to isolate the actual column names:
R

col_names <- readLines("kddcup.names")
col_names <- col_names[-1]
col_names <- sapply(col_names, function(x) strsplit(x, ":")[[1]][1])
col_names <- trimws(col_names)
colnames(netWorkDataset) <- col_names
colnames(netWorkDataset)[ncol(netWorkDataset)] <- "class"

The last column was manually renamed to “class” to improve clarity for the classification task.
Data Persistence

Finally, the cleaned data frame was written to disk for reuse:
R

write_csv(netWorkDataset, "kdd_clean.csv")

🧹 Data Cleaning

Multiple cleaning steps were performed, following standard processing practices.
1. Removing Missing Values
R

na.omit(netWorkDataset)

The dataset contains no substantial NA values by design, but this step ensures consistency.
2. Removing Duplicate Rows
R

netWorkDataset <- unique(netWorkDatset)

This prevents biased statistics or inflated sample counts.
3. Converting Character Variables to Factors
R

char_cols <- sapply(netWorkDataset, is.character)
netWorkDataset[, char_cols] <- lapply(netWorkDataset[, char_cols], as.factor)

The KDD dataset includes categorical features like protocol_type, service, and flag, which are best represented as factors for analysis and modeling.
4. Converting Integer Columns to Numeric
R

int_cols <- sapply(netWorkDataset, is.integer)
netWorkDataset[int_cols] <- lapply(netWorkDataset[int_cols], as.numeric)

This ensures compatibility with statistical functions and the ggplot2 visualization package.
Steps Intentionally Not Applied

    No feature/column removal was done at this stage to avoid losing potentially important information before the main analysis.

Results of Data Cleaning

The starting dataset contained approximately 5,000,000 rows. After this cleaning process (primarily the removal of duplicates), the dataset size was reduced to approximately 1,000,000 rows.
🛠️ Data Transformation
Feature Selection

For the analysis, only a subset of relevant features was selected:
R

netWorkDataset_clean <- select(netWorkDataset, duration, protocol_type, service, flag, src_bytes, dst_bytes, count, srv_count, serror_rate, srv_serror_rate, rerror_rate, srv_rerror_rate, logged_in, is_host_login, is_guest_login, dst_host_count, dst_host_srv_count, dst_host_same_srv_rate, dst_host_diff_srv_rate, dst_host_same_src_port_rate, class)

This reduction eliminates unused fields (like low-level content features) and helps focus on variables commonly used for network intrusion detection.
Feature Engineering

Two new variables were created to better quantify the connection behavior:
1. total_bytes

This represents the total traffic between the source and destination:
total_bytes=src_bytes+dst_bytes

This helps quantify the intensity of each connection.
2. byte_ratio

This calculates the proportion between source and destination bytes:
byte_ratio={0src_bytes/dst_bytes​if dst_bytes=0otherwise​

This is useful for distinguishing attack patterns where either outgoing or incoming traffic dominates.
Adding New Columns

The new columns were added using the following R code:
R

netWorkDataset_clean <- mutate(netWorkDataset_clean,
                               total_bytes = src_bytes + dst_bytes,
                               byte_ratio = ifelse(dst_bytes == 0, 0, src_bytes / dst_bytes)
)

📊 Exploratory Data Analysis (EDA)

The following plots were generated to explore the dataset. Note: For many of the graphs, a log(x+1) transformation was applied to mitigate the effect of extreme outliers. This option is interactive in the Web Application.
1. Treemap (Class Distribution)

    Explanation: Hierarchical visualization where the area represents the volume of connections per attack group.

    Why: To visually grasp the severity of class imbalance in the dataset.

    Conclusion: "Normal" and DoS (Denial of Service) traffic dominate the dataset, while U2R (User-to-Root) and R2L (Remote-to-Local) attacks are statistically negligible.

2. Stacked Bars (Group Composition)

    Explanation: Normalized bars showing the proportion of specific attack subtypes within each general group.

    Why: To identify which specific signatures are most prevalent in each category.

    Conclusion: Most groups are driven by a single dominant attack type (e.g., smurf within DoS), highlighting a lack of diversity within specific groups.

3. ECDF (Empirical Cumulative Distribution Function)

    Explanation: Plots cumulative probability to compare how variables increase across groups.

    Why: To detect "robotic" or automated patterns distinct from human behavior.

    Conclusion: Automated attacks show vertical "steps" (indicating constant values), contrasting with the smooth curves of normal traffic, which suggests predictable, scripted behavior in attacks.

4. Violin Plot

    Explanation: Merges density shapes with summary statistics for individual classes.

    Why: To visualize the variance and distinct "fingerprint" of each attack.

    Conclusion: Malicious traffic often shows narrow, rigid density peaks, contrasting with the high variance typical of normal user behavior, suggesting a tightly controlled nature of the attacks.

5. Scatter Plot (Src vs Dst Bytes)

    Explanation: Plots source against destination bytes using log-scale to handle outliers. Duration is represented by point size, and attack type by color.

    Why: To analyze the directionality and symmetry of data flow.

    Conclusion: Attacks cluster on the axes (unidirectional flow, e.g., high src_bytes and low dst_bytes), distinguishing them from the correlated input/output observed in normal traffic.

6. Correlation Matrix

    Explanation: A Spearman correlation heatmap for numerical variables.

    Why: To detect redundancy and multicollinearity between features.

    Conclusion: High correlation among error-rate variables (serror_rate, srv_serror_rate, etc.) suggests that dimensionality reduction techniques (like PCA) can be safely applied to these features without significant loss of information.

7. Histograms

    Explanation: Frequency distributions for selected variables across different groups.

    Why: To assess data skewness and the need for transformations.

    Conclusion: Variables are heavily right-skewed and non-Gaussian, validating the decision to apply log-transformations before modeling to normalize distributions.

8. Boxplots

    Explanation: Compares medians and ranges while visually trimming extreme outliers (e.g., to the 1st and 99th percentiles).

    Why: To compare central tendencies without the bias of extreme anomalies.

    Conclusion: "Probe" attacks exhibit distinctively higher medians in count-based variables compared to normal traffic, indicating an unusually high number of connections from the source during the probing phase.

9. PCA (Principal Component Analysis)

    Explanation: Projects high-dimensional data onto the first two principal components.

    Why: To evaluate if classes are linearly separable in low dimensions.

    Conclusion: "DoS" and "Probe" classes separate well from the "Normal" cluster. However, "U2R" and "R2L" overlap significantly with "Normal" traffic, indicating their detection will be more difficult for linear models.

🌐 Web Application
Description

To support interactive visual exploration, an additional web dashboard was implemented using the R Shiny framework. This application provides an intuitive interface where users can explore the top 12 attack types dynamically, adjusting which classes to display and examining their behavior in a multivariable scatterplot without modifying any code.
R/Shiny Interface Code

The structure of the application is defined as follows:
R

ui <- fluidPage(
  titlePanel("Scatter: src_bytes vs dst_bytes (Top 12 ataques)"),
  sidebarLayout(
    sidebarPanel(
      h4("Mostrar/Ocultar clases"),
      checkboxGroupInput(
        inputId = "clases_mostrar",
        label = "Selecciona las clases a visualizar:",
        choices = top12_attacks,
        selected = top12_attacks
      )
    ),
    mainPanel(
      plotOutput("scatterPlot", height = "600px")
    )
  )
)

Key Interface Components
Component	Description
Sidebar Controls	The left panel includes a checkbox selector allowing users to show or hide any of the top 12 attack classes. This enables focused inspection of specific subsets of the dataset.
Interactive Scatter Panel	The main area displays a multivariable scatterplot (src_bytes vs. dst_bytes), enriched with duration-based point sizing and custom color mapping for each attack type. The plot updates in real-time based on the user’s selections.
R/Shiny Server Logic
R

server <- function(input, output, session) {
  output$scatterPlot <- renderPlot({
    df_filtrado <- netWorkDataset_top12 %>%
      filter(class %in% input$clases_mostrar)

    ggplot(df_filtrado,
           aes(x = src_bytes, y = dst_bytes, color = class, size = duration)) +
      geom_point(alpha = 0.6) +
      # ... scale and lab commands ...
  })
}

shinyApp(ui = ui, server = server)
