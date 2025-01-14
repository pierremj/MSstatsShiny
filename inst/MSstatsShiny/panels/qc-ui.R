### sidebar ###
sbp_params = sidebarPanel(
  
  
  # transformation
  
  conditionalPanel(condition = "input.DDA_DIA == 'TMT' || input.PTMTMT == 'Yes'",
                   h4("1. Peptide level normalization", 
                      tipify(icon("question-circle"), 
                             title = "Global median normalization on peptide level data, equalizes medians across all the channels and runs")),
                   checkboxInput("global_norm", "Yes", value = T)),
  
  conditionalPanel(condition = "input.DDA_DIA !== 'TMT' && input.PTMTMT == 'No'",
                   radioButtons("log", 
                                label= h4("1. Log transformation", 
                                          tipify(icon("question-circle"), 
                                                 title = "Logarithmic transformation applied to the Intensity column")), 
                                c(log2 = "2", log10 = "10"))),
  
  
  tags$hr(),
  
  conditionalPanel(condition = "input.DDA_DIA == 'TMT' || input.PTMTMT == 'Yes'",
                   selectInput("summarization", 
                               label = h4("2. Summarization method", 
                                          tipify(icon("question-circle"), 
                                                 title = "Select method to be used for protein summarization. For details on each option please see Help tab")), 
                               c("MSstats" = "msstats", 
                                 "Tukeys median polish" = "MedianPolish", 
                                 "Log(Sum)" = "LogSum","Median" = "Median"), 
                               selected = "log")),
  
  conditionalPanel(condition = "(input.DDA_DIA == 'TMT' || input.PTMTMT == 'Yes') && input.summarization == 'msstats'",
                   checkboxInput("null", label = p("Do not apply cutoff", 
                                                   tipify(icon("question-circle"), 
                                                          title = "Maximum quantile for deciding censored missing values, default is 0.999"))),
                   numericInput("maxQC", NULL, 0.999, 0.000, 1.000, 0.001)),
  
  # Normalization
  conditionalPanel(condition="input.DDA_DIA !== 'TMT' && input.PTMTMT !== 'Yes'",
                   selectInput("norm", 
                               label = h4("2. Normalization", 
                                          tipify(icon("question-circle"), 
                                                 title = "Normalization to remove systematic bias between MS runs. For more information visit the Help tab")), 
                               c("none" = "FALSE", "equalize medians" = "equalizeMedians", 
                                 "quantile" = "quantile", "global standards" = "globalStandards"), 
                               selected = "equalizeMedians")),
  conditionalPanel(condition = "input.DDA_DIA !== 'TMT' && input.norm == 'globalStandards' && input.DDA_DIA !== PTM",
                   radioButtons("standards", "Choose type of standards", 
                                c("Proteins", "Peptides")),
                   uiOutput("Names")
  ),
  tags$hr(),
  
  conditionalPanel(
    condition = "input.DDA_DIA == 'TMT' || input.PTMTMT == 'Yes'",
    h4("3. Local protein normalization",
       tipify(icon("question-circle"), 
              title = "Reference channel based normalization between MS runs on protein level data. Requires one reference channel in each MS run, annotated by ‘Norm’ in Condition column of annotation file")),
    checkboxInput("reference_norm", "Yes", value = T),
    tags$hr(),
    h4("4. Filtering"),
    checkboxInput("remove_norm_channel", "Remove normalization channel", value = T)
    
  ),
  
  
  conditionalPanel(
    condition = "input.DDA_DIA !== 'TMT' || input.PTMTMT !== 'Yes'",
    
    # features
    
    #h4("3. Used features"),
    radioButtons("features_used",
                 label = h4("3. Used features"),
                 c("Use all features" = "all", "Use top N features" = "topN", 
                   "Remove uninformative features & outliers" = "highQuality")),
    #checkboxInput("all_feat", "Use all features", value = TRUE),
    conditionalPanel(condition = "input.features_used =='topN'",
                     uiOutput("features")),
    #uiOutput("features"),
    tags$hr(),
    
    ### censoring
    h4("4. Missing values (not random missing or censored)"),
    radioButtons('censInt', 
                 label = h5("Assumptions for missing values", 
                            tipify(icon("question-circle"), 
                                   title = "Processing software report missing values differently; please choose the appropriate options to distinguish missing values and if censored/at random")), 
                 c("assume all NA as censored" = "NA", "assume all between 0 \
                   and 1 as censored" = "0", 
                   "all missing values are random" = "null"), 
                 selected = "NA"),
    MSstatsShiny::radioTooltip(id = "censInt", choice = "NA", title = "It assumes that all \
                 NAs in Intensity column are censored.", placement = "right", 
                 trigger = "hover"),
    MSstatsShiny::radioTooltip(id = "censInt", choice = "0", title = "It assumes that all \
                 values between 0 and 1 in Intensity column are censored.  NAs \
                 will be considered as random missing.", placement = "right",
                 trigger = "hover"),
    MSstatsShiny::radioTooltip(id = "censInt", choice = "null", title = "It assumes that all \
                 missing values are randomly missing.", placement = "right", 
                 trigger = "hover"),
    
    # max quantile for censored
    h5("Max quantile for censored", tipify(icon("question-circle"), 
                                           title = "Max quantile for censored")),
    checkboxInput("null1", label = "Do not apply cutoff to censor missing values"),
    numericInput("maxQC1", NULL, 0.999, 0.000, 1.000, 0.001),
    
    
    # MBi
    h4("5. Imputation"),
    conditionalPanel(condition = "input.censInt == 'NA' || input.censInt == '0'",
                     checkboxInput("MBi", 
                                   label = p("Model based imputation", 
                                             tipify(icon("question-circle"), 
                                                    title = "If unchecked the values set as cutoff for censored will be used")), 
                                   value = TRUE
                     )),
    # # cutoff for censored
    # conditionalPanel(condition = "input.censInt == 'NA' || input.censInt == '0'",
    #                  selectInput("cutoff", "cutoff value for censoring", 
    #                              c("min value per feature"="minFeature", 
    #                                "min value per feature and run"="minFeatureNRun", 
    #                                "min value per run"="minRun"))),
    
    
    tags$hr(),
    tags$style(HTML('#run{background-color:orange}')),
    ### summary method
    
    h4("6. Summarization", tipify(icon("question-circle"), 
                                  title = "Run-level summarization method")),
    p("method: TMP"),
    p("For linear summarzation please use command line"),
    tags$hr(),
    
    # remove features with more than 50% missing 
    checkboxInput("remove50", "remove runs with over 50% missing values"),
    
  ),
  
  tags$hr(),
  actionButton("run", "Run protein summarization"),
  # run 
  width = 3
)


### main panel ###  

main = mainPanel(
  
  h3("Please run protein summarization in the side panel."),
  h3(textOutput("caption", container = span)),
  
  tabsetPanel(
    tabPanel("Summarized Results", 
             wellPanel(
               fluidRow(
                 h4("Download summary of protein abundance", 
                    tipify(icon("question-circle"), 
                           title="Model-based quantification for each condition or for each biological samples per protein.")),
                 radioButtons("typequant", 
                              label = h4("Type of summarization"), 
                              c("Sample level summarization" = "Sample", 
                                "Group level summarization" = "Group")),
                 radioButtons("format", "Save as", c("Wide format" = "matrix", 
                                                     "Long format" = "long")),
                 actionButton("update_results", "Update Summarized Results"),
                 downloadButton("download_summary", "Download")
               )),
             #column(7,
             h4("Table of abundance"),
             uiOutput("abundance")
             #)
             #)
    ),
    tabPanel("Summarization Plots",
             wellPanel(
                                selectInput("type1",
                                            label = h5("Select plot type", 
                                                       tipify(icon("question-circle"), 
                                                              title="For details on plotting options please see the Help tab.")), 
                                            c("Quality Control Plots"="QCPlot", 
                                              "Profile Plots"="ProfilePlot")),
               conditionalPanel(condition = "input.type1 === 'ProfilePlot'",
                                checkboxInput("summ", "Show plot with summary"),
                                selectInput("fname",  
                                            label = h5("Feature legend", 
                                                       tipify(icon("question-circle"),
                                                              title = "Type of legend to use in plot")), 
                                            c("Transition level"="Transition", 
                                              "Peptide level"="Peptide", 
                                              "No feature legend"="NA"))
                                
               ),

               uiOutput("Which"),
               tags$br()
             ),
             # conditionalPanel(condition="$('html').hasClass('shiny-busy')",
             #                  tags$br(),
             #                  tags$br(),
             #                  tags$h4("Calculation in progress...")),
             uiOutput("showplot"),
             disabled(downloadButton("saveplot", "Save this plot"))
    ),
    tabPanel("Download Data", 
             #verbatimTextOutput('effect'),
             # conditionalPanel(condition="$('html').hasClass('shiny-busy')",
             #                  tags$br(),
             #                  tags$br(),
             #                  tags$h4("Calculation in progress...")),
             #tags$div(id='download_buttons')
             tags$br(),
             conditionalPanel(condition="input.DDA_DIA !== 'PTM'",
                              disabled(downloadButton("prepr_csv","Download .csv of feature level data")),
                              disabled(downloadButton("summ_csv","Download .csv of protein level data"))
             ),
             conditionalPanel(condition="input.DDA_DIA == 'PTM'",
                              disabled(downloadButton("prepr_csv_ptm","Download .csv of PTM feature level data")),
                              disabled(downloadButton("summ_csv_ptm","Download .csv of PTM level data")),
                              tags$br(),
                              disabled(downloadButton("prepr_csv_prot","Download .csv of unmod protein feature level data")),
                              disabled(downloadButton("summ_csv_prot","Download .csv of protein level data"))
             )
    )
  )
)

########################################################################################

qc = fluidPage(
  use_busy_spinner(spin = "fading-circle"),
  tags$style(HTML('#proceed6{background-color:orange}')),
  headerPanel("Process and quantify data"),
  p("Feature summarization and missing value imputation. Includes options for vizualizing summarization through data tables and multiple plots. All outputs are available to download in 'csv' format."),
  tags$br(),
  sbp_params,
  column(width = 8,
         main,
         uiOutput('submit.button')
  )
)