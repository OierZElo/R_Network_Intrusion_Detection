library(shiny)
library(dplyr)
library(ggplot2)

# ----------------------------
# 0. Preprocesamiento
# ----------------------------

# Ordenar el resumen y obtener los 12 ataques más frecuentes
attack_summary_ordered <- attack_summary[order(-attack_summary$n), ]
top12_attacks <- attack_summary_ordered$class[1:12]

# Filtrar dataset original
netWorkDataset_top12 <- netWorkDataset_clean %>%
  filter(class %in% top12_attacks)

# Convertir class a factor ordenado
netWorkDataset_top12$class <- factor(netWorkDataset_top12$class, levels = top12_attacks)

# Colores manuales
colores_12 <- c(
  "normal."      = "#aec7e8",
  "neptune."     = "#FF7300",
  "satan."       = "#008229",
  "ipsweep."     = "#FF0000",
  "portsweep."   = "#6C009E",
  "smurf."       = "#9E4C00",
  "nmap."        = "#00FBFF",
  "back."        = "#7f7f7f",
  "teardrop."    = "#00FF22",
  "warezclient." = "#FF00E9",
  "pod."         = "#0018FF",
  "guess_passwd." = "#ffbb78"
)

# ----------------------------
# 1. UI
# ----------------------------
ui <- fluidPage(
  
  titlePanel("Scatter: src_bytes vs dst_bytes (Top 12 ataques)"),
  
  sidebarLayout(
    
    sidebarPanel(
      h4("Mostrar/Ocultar clases"),
      
      checkboxGroupInput(
        inputId = "clases_mostrar",
        label   = "Selecciona las clases a visualizar:",
        choices = top12_attacks,
        selected = top12_attacks   # todas activas al inicio
      )
    ),
    
    mainPanel(
      plotOutput("scatterPlot", height = "600px")
    )
    
  )
)

# ----------------------------
# 2. SERVER
# ----------------------------
server <- function(input, output, session) {
  
  output$scatterPlot <- renderPlot({
    
    # Filtrar según checkboxes
    df_filtrado <- netWorkDataset_top12 %>%
      filter(class %in% input$clases_mostrar)
    
    ggplot(df_filtrado,
           aes(x = src_bytes, y = dst_bytes, color = class, size = duration)) +
      geom_point(alpha = 0.6) +
      scale_color_manual(values = colores_12) +
      scale_size_continuous(range = c(1, 10)) +
      labs(
        title = "Scatter multivariable: src_bytes vs dst_bytes (Top 12 ataques)",
        x = "src_bytes",
        y = "dst_bytes",
        color = "class",
        size = "Duration"
      ) +
      theme_minimal(base_size = 14) +
      guides(color = guide_legend(override.aes = list(shape = 15, size = 5)))
  })
}

# ----------------------------
# 3. Lanzar app
# ----------------------------
shinyApp(ui = ui, server = server)
