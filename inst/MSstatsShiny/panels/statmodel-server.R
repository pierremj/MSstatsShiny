######### UI #########

# choices of groups for contrast matrix

choices = reactive({
  if (input$DDA_DIA == "PTM" & input$PTMTMT == "Yes"){
    levels(preprocess_data()$PTM$ProteinLevelData$Condition)
  } else if(input$DDA_DIA == "PTM" & input$PTMTMT == "No"){
    levels(preprocess_data()$PTM$ProteinLevelData$GROUP)
  } else if(input$DDA_DIA=="TMT"){
    levels(preprocess_data()$ProteinLevelData$Condition)
  }
  else{
    levels(preprocess_data()$ProteinLevelData$GROUP)
  }
  
})
row = reactive({rep(0, length(choices()))})
contrast = reactiveValues()
comp_list = reactiveValues()
significant = reactiveValues()


observe({
  if(input$DDA_DIA == "TMT"){
    hide("Design")
  }
  else{
    shinyjs::show("Design")
  }
})

output$choice1 = renderUI({
  selectInput("group1", "Group 1", choices())
})

output$choice2 = renderUI({
  selectInput("group2", "Group 2", choices())
})

output$choice3 = renderUI({
  selectInput("group3", "", choices())
})

output$comp_name = renderUI({
  textInput("comp_name", label = "Comparison Name", value = "")
})

output$weights = renderUI({
  
  lapply(1:length(choices()), function(i) {
    list(
      numericInput(paste0("weight", i), label = choices()[i], value=0))  
  })
})

# rownames for matrix

Rownames = eventReactive(input$submit | input$submit1 | input$submit2 | input$submit3, {
  req(input$def_comp)
  req(input$DDA_DIA)
  tryCatch({
    rownames(matrix_build())},
    error=function(e){})
})

# choices of comparisons/proteins to plot

output$WhichComp = renderUI ({
  selectInput("whichComp", 
              label = h5("Select comparison to plot"), c("all", Rownames()), selected = "all")
})

output$WhichProt = renderUI ({
  selectInput("whichProt",
              label = h4("which protein to plot"), unique(get_data()[[1]]))
})

output$WhichProt1 = renderUI ({
  selectizeInput("whichProt1",
                 label = h4("which protein to plot"), c("", unique(get_data()[[1]])))
})


########## functions ########

# build matrix

observeEvent(input$def_comp, {
  contrast$matrix = NULL
  comp_list$dList = NULL
})

observeEvent(input$proceed1, {
  contrast$matrix = NULL
  comp_list$dList = NULL
  significant$result = NULL
})

## Check contrast matrix was created correctly
check_cond = eventReactive(input$submit | input$submit1 | input$submit2 | input$submit3, {
  req(input$def_comp)
  req(input$DDA_DIA)
  if(input$def_comp == "custom") {
    validate(
      need(input$group1 != input$group2, "Please select different groups")
    )}
  
  else if(input$def_comp == "custom_np") {
    
    wt_sum = 0
    for (index in 1:length(choices())){
      wt_sum = wt_sum + input[[paste0("weight", index)]]
    }
    
    validate(
      need( wt_sum == 0, 
            "The contrast weights should sum up to 0")
    )}
})

matrix_build = eventReactive(input$submit | input$submit1 | input$submit2 | input$submit3, {
  req(input$def_comp)
  req(input$DDA_DIA)
  if(input$def_comp == "custom") {
    if(input$group1 == input$group2){
      return(contrast$matrix)
    }
    index1 = reactive({which(choices() == input$group1)})
    index2 = reactive({which(choices() == input$group2)})
    comp_list$dList = unique(c(isolate(comp_list$dList), paste(input$group1, "vs", 
                                                               input$group2, sep = " ")))
    contrast$row = matrix(row(), nrow=1)
    contrast$row[index1()] = 1
    contrast$row[index2()] = -1
    if (is.null(contrast$matrix)) {
      contrast$matrix = contrast$row 
    } 
    else {
      contrast$matrix = rbind(contrast$matrix, contrast$row)
      contrast$matrix = rbind(contrast$matrix[!duplicated(contrast$matrix),])
    }
    print(contrast$matrix)
    rownames(contrast$matrix) = comp_list$dList
    colnames(contrast$matrix) = choices()
  }
  
  else if(input$def_comp == "custom_np") {
    
    wt_sum = 0
    for (index in 1:length(choices())){
      wt_sum = wt_sum + input[[paste0("weight", index)]]
    }
    
    if(wt_sum != 0){
      return(contrast$matrix)
    }
    
    comp_list$dList = unique(c(isolate(comp_list$dList), input$comp_name))
    contrast$row = matrix(row(), nrow=1)
    
    for (index in 1:length(choices())){
      contrast$row[index] = input[[paste0("weight", index)]]
    }
    
    if (is.null(contrast$matrix)) {
      contrast$matrix = contrast$row 
    } else {
      contrast$matrix = rbind(contrast$matrix, contrast$row)
      contrast$matrix = rbind(contrast$matrix[!duplicated(contrast$matrix),])
    }
    print(contrast$matrix)
    rownames(contrast$matrix) = comp_list$dList
    colnames(contrast$matrix) = choices()
  }
  
  else if (input$def_comp == "all_one") {
    print(choices())
    for (index in 1:length(choices())) {
      index3 = reactive({which(choices() == input$group3)})
      if(index == index3()) next
      if(input$DDA_DIA=="TMT"){
        comp_list$dList = c(isolate(comp_list$dList), 
                            paste(choices()[index], " vs ", 
                                  input$group3, sep = ""))
      } else{
        comp_list$dList = c(isolate(comp_list$dList), 
                            paste(choices()[index], " vs ", 
                                  input$group3, sep = ""))
      }
      
      contrast$row = matrix(row(), nrow=1)
      contrast$row[index] = 1
      contrast$row[index3()] = -1
      if (is.null(contrast$matrix)) {
        contrast$matrix = contrast$row 
      } else {
        contrast$matrix = rbind(contrast$matrix, contrast$row)
      }
      rownames(contrast$matrix) = comp_list$dList
      colnames(contrast$matrix) = choices()
    }
  }
  else if (input$def_comp == "all_pair") {
    contrast$matrix = NULL
    for (index in 1:length(choices())) {
      for (index1 in 1:length(choices())) {
        if (index == index1) next
        if (index < index1) {
          if(input$DDA_DIA=="TMT"){
            comp_list$dList = c(isolate(comp_list$dList), 
                                paste(choices()[index], " vs ", 
                                      choices()[index1], sep = ""))
          } else{
            comp_list$dList = c(isolate(comp_list$dList), 
                                paste(choices()[index], " vs ", 
                                      choices()[index1], sep = ""))
          }
          contrast$row = matrix(row(), nrow=1)
          contrast$row[index] = 1
          contrast$row[index1] = -1
          if (is.null(contrast$matrix)) {
            contrast$matrix = contrast$row 
          } else {
            contrast$matrix = rbind(contrast$matrix, contrast$row)
            contrast$matrix = rbind(contrast$matrix[!duplicated(contrast$matrix),])
          }
          rownames(contrast$matrix) = comp_list$dList
          colnames(contrast$matrix) = choices()
        }
      }
    }
  }
  enable("calculate")
  return(contrast$matrix)
})

# clear matrix

observeEvent({input$clear | input$clear1 | input$clear2 | input$clear3},  {
  disable("calculate")
  comp_list$dList = NULL
  contrast$matrix = NULL
})

# Run Models
data_comparison = eventReactive(input$calculate, {
  
  input_data = preprocess_data()
  contrast.matrix = matrix_build()
  
  print(matrix_build())
  if (input$DDA_DIA == "PTM" & input$PTMTMT == "Yes"){
    model_ptm = MSstatsShiny::tmt_model(input_data$PTM, input, contrast.matrix)
    model_protein = MSstatsShiny::tmt_model(input_data$PROTEIN, input, contrast.matrix)
    model_adj = MSstatsShiny::apply_adj(model_ptm$ComparisonResult,
                                        model_protein$ComparisonResult)
    model = list('PTM.Model' = model_ptm$ComparisonResult, 
                 'PROTEIN.Model' = model_protein$ComparisonResult,
                 'ADJUSTED.Model' = model_adj)
    
  } else if(input$DDA_DIA == "PTM" & input$PTMTMT == "No"){
    model_ptm = MSstatsShiny::lf_model(input_data$PTM, contrast.matrix)
    model_protein = MSstatsShiny::lf_model(input_data$PROTEIN, contrast.matrix)
    model_adj = MSstatsShiny::apply_adj(model_ptm$ComparisonResult,
                                        model_protein$ComparisonResult)
    model = list('PTM.Model' = model_ptm$ComparisonResult, 
                 'PROTEIN.Model' = model_protein$ComparisonResult,
                 'ADJUSTED.Model' = model_adj)
    
  } else if(input$DDA_DIA=="TMT"){
    model = MSstatsShiny::tmt_model(input_data, input, contrast.matrix)
  }
  else{
    model = MSstatsShiny::lf_model(input_data, contrast.matrix)
  }
  
  return(model)
})

data_comparison_code = eventReactive(input$calculate, { 
  
  codes = preprocess_data_code()
  comp.mat = matrix_build()
  
  codes = paste(codes, "\n# Create the contrast matrix\n", sep = "")
  codes = paste(codes, "contrast.matrix = NULL\n", sep = "")
  for(i in 1:nrow(comp.mat)){
    codes = paste(codes, "comparison = matrix(c(", toString(comp.mat[i,]),"),nrow=1)\n", sep = "")
    codes = paste(codes, "contrast.matrix = rbind(contrast.matrix, comparison)\n", sep = "")
    
  }
  
  codes = paste(codes, "row.names(contrast.matrix)=c(\"", paste(row.names(comp.mat), collapse='","'),"\")\n", sep = "")
  codes = paste(codes, "colnames(contrast.matrix)=c(\"", paste(colnames(comp.mat), collapse='","'),"\")\n", sep = "")
  
  if(input$DDA_DIA == "TMT"){
    codes = paste(codes, "\n# Model-based comparison\n", sep = "")
    codes = paste(codes,"model = MSstatsTMT::groupComparisonTMT(summarized,
                   contrast.matrix = contrast.matrix,
                   moderated = ", input$moderated,",\t\t\t\t   
                   adj.method = \"BH\",
                   remove_norm_channel = TRUE,
                   remove_empty_channel = TRUE
                   )\n", sep = "")
  } else if (input$DDA_DIA == "PTM"){
    if (input$PTMTMT == "Yes"){
      dt = "TMT"
    } else {
      dt = "LabelFree"
    }
    codes = paste(codes, "\n# Model-based comparison\n", sep = "")
    codes = paste(codes,"model = MSstatsPTM::groupComparisonPTM(summarized, '", 
                  dt, "', \t\t\t\t   
                  contrast.matrix = contrast.matrix)\n", sep = "")
  }
  else{
    
    codes = paste(codes, "\n# Model-based comparison\n", sep = "")
    codes = paste(codes,"model = MSstats::groupComparison(contrast.matrix, summarized)\n", sep = "")
  }
  if (input$DDA_DIA == "PTM"){
    codes = paste(codes, "groupComparisonPlotsPTM(data=model,
                           type=\"Enter VolcanoPlot, Heatmap, or ComparisonPlot\",
                           which.Comparison=\"all\",
                           which.PTM=\"all\",
                           address=\"\")\n", sep="")
  } else {
    codes = paste(codes, "groupComparisonPlots(data=model$ComparisonResult,
                           type=\"Enter VolcanoPlot, Heatmap, or ComparisonPlot\",
                           which.Comparison=\"all\",
                           which.Protein=\"all\",
                           address=\"\")\n", sep="")
  }
  
  return(codes)
})


round_df = function(df) {
  nums = vapply(df, is.numeric, FUN.VALUE = logical(1))
  
  df[,nums] = round(df[,nums], digits = 4)
  
  (df)
}

SignificantProteins = eventReactive(input$calculate,{
  if (input$DDA_DIA == "PTM"){
    data_comp = data_comparison()
    sig_unadj = data_comp$PTM.Model[
      data_comp$PTM.Model$adj.pvalue < input$signif]
    sig_prot = data_comp$PROTEIN.Model[
      data_comp$PROTEIN.Model$adj.pvalue < input$signif]
    sig_adj = data_comp$ADJUSTED.Model[
      data_comp$ADJUSTED.Model$adj.pvalue < input$signif]
    significant = list(PTM.Model=sig_unadj, 
                       PROTEIN.Model=sig_prot, 
                       ADJUSTED.Model=sig_adj)
    
  } else if(input$DDA_DIA=="TMT"){
    data_comp = data_comparison()
    significant = data_comp$ComparisonResult[
      data_comp$ComparisonResult$adj.pvalue < input$signif, ]
    
  } else {
    significant = with(data_comparison(), round_df(ComparisonResult[
      ComparisonResult$adj.pvalue < input$signif, ]))
    
  }
  return(significant)
})

group_comparison = function(saveFile1, pdf) {
  
  id1 = as.character(UUIDgenerate(FALSE))
  id_address1 = paste("tmp/",id1, sep = "")
  path1 = function() {
    if (saveFile1) {
      path1_id = paste("www/", id_address1, sep = "")
    }
    else {
      path1_id = FALSE
    }
    return(path1_id)
  }
  
  if (input$DDA_DIA=="PTM"){
    plot1 = groupComparisonPlotsPTM(data_comparison(),
                                    input$typeplot,
                                    sig=input$sig,
                                    FCcutoff=input$FC,
                                    logBase.pvalue=as.integer(input$logp),
                                    ProteinName = input$pname,
                                    which.Comparison = input$whichComp,
                                    address = path1())
    
    
  } else if(input$DDA_DIA=="TMT"){
    
    plot1 = MSstatsShiny::groupComparisonPlots2(data=data_comparison()$ComparisonResult,
                                                type=input$typeplot,
                                                sig=input$sig,
                                                FCcutoff=input$FC,
                                                logBase.pvalue=input$logp,
                                                ProteinName=input$pname,
                                                numProtein=input$nump, 
                                                clustering=input$cluster, 
                                                which.Comparison=input$whichComp,
                                                which.Protein = input$whichProt,
                                                address=path1(),
                                                savePDF=pdf
    )
    
  } else{
    
    plot1 = MSstatsShiny::groupComparisonPlots2(data=data_comparison()$ComparisonResult,
                                                type=input$typeplot,
                                                sig=input$sig,
                                                FCcutoff=input$FC,
                                                logBase.pvalue=input$logp,
                                                ProteinName=input$pname,
                                                numProtein=input$nump, 
                                                clustering=input$cluster, 
                                                which.Comparison=input$whichComp,
                                                which.Protein = input$whichProt,
                                                address=path1(),
                                                savePDF=pdf
    )
    
  }
  
  if(saveFile1) {
    return(id_address1)
  }
  else {
    return(plot1)
  }
}

# model assumptions plots

assumptions1 = function(saveFile3, protein) {
  if (input$whichProt1 != "") {
    id2 = as.character(UUIDgenerate(FALSE))
    id_address2 = paste("tmp/",id2, sep = "")
    path2 = function(saveFile3)  {
      if (saveFile3) {
        path_id2 = paste("www/", id_address2, sep = "")
      } 
      else {
        path_id2 = FALSE
      }
      return (path_id2)
    }
    
    plots = modelBasedQCPlots(data=data_comparison(), type=input$assum_type, 
                              which.Protein = protein, address = path2())
    
    if(saveFile3) {
      return(path2())
    }
    else {
      return(plots)
    }
  }
  else {
    return(NULL)
  }
}



########## output ##########

# download comparison data

output$compar = downloadHandler(
  filename = function() {
    paste("comparison-", Sys.Date(), ".csv", sep="")
  },
  content = function(file) {
    write.csv(data_comparison()$ComparisonResult, file)
  })

output$model_QC = downloadHandler(
  filename = function() {
    paste("ModelQC-", Sys.Date(), ".csv", sep="")
  },
  content = function(file) {
    write.csv(data_comparison()$ModelQC, file)
  })

output$fitted_v = downloadHandler(
  filename = function() {
    paste("model_summary-", Sys.Date(), ".csv", sep="")
  },
  content = function(file) {
    write.csv(capture.output(data_comparison()$fittedmodel), file)
  })

# matrix

output$message = renderText({
  check_cond()
})
observeEvent(input$calculate, {output$code.button = renderUI(
  downloadButton("download_code", "Download analysis code", icon("download"),
                 style="color: #000000; background-color: #75ba82; border-color: #000000"))})

output$matrix = renderUI({
  tagList(
    h2("Comparison matrix"),
    br(),
    textOutput("message"),
    br(),
    if (is.null(contrast$matrix)) {
      ""
    } else {
      dataTableOutput("table") 
    }
  )
})

output$table = renderDataTable({
  matrix_build()
}
)

# table of significant proteins
output$table_results = renderUI({
  req(data_comparison())
  req(SignificantProteins())
  
  if (is.null(significant)) {
    
    tagList(
      tags$br())
  } else {
    tagList(
      tags$br(),
      h2("Results"),
      h5("There are ",textOutput("number", inline = TRUE),"significant proteins"),
      tags$br(),
      dataTableOutput("significant"),
      downloadButton("download_compar", "Download all modeling results"),
      downloadButton("download_signif", "Download significant proteins")
      
    )
  }
})

output$adj_table_results = renderUI({
  req(data_comparison())
  req(SignificantProteins())
  significant = SignificantProteins()
  print(significant$ADJUSTED.Model)
  if (is.null(significant$ADJUSTED.Model)) {
    print(TRUE)
    tagList(
      tags$br())
  } else {
    tagList(
      tags$br(),
      h2("Adjusted PTM Modeling Results"),
      h5("There are ",textOutput("number_adj", inline = TRUE),"significant PTMs"),
      tags$br(),
      dataTableOutput("adj_significant"),
      downloadButton("download_compar_adj", "Download all modeling results"),
      downloadButton("download_signif_adj", "Download significant PTMs")
    )
  }
})

output$unadj_table_results = renderUI({
  req(data_comparison())
  req(SignificantProteins())
  significant = SignificantProteins()
  if (is.null(significant$PTM.Model)) {
    tagList(
      tags$br())
  } else {
    tagList(
      tags$br(),
      h2("Unadjusted PTM Modeling Results"),
      h5("There are ",textOutput("number_unadj", inline = TRUE),"significant PTMs"),
      tags$br(),
      dataTableOutput("unadj_significant"),
      downloadButton("download_compar_unadj", "Download all modeling results"),
      downloadButton("download_signif_unadj", "Download significant PTMs")
    )
  }
})

output$prot_table_results = renderUI({
  req(data_comparison())
  req(SignificantProteins())
  significant = SignificantProteins()
  if (is.null(significant$PTM.Model)) {
    tagList(
      tags$br())
  } else {
    tagList(
      tags$br(),
      h2("Protein Modeling Results"),
      h5("There are ",textOutput("number_prot", inline = TRUE),"significant proteins"),
      tags$br(),
      dataTableOutput("prot_significant"),
      downloadButton("download_compar_prot", "Download all modeling results"),
      downloadButton("download_signif_prot", "Download significant proteins")
    )
  }
})

output$significant = renderDataTable({
  SignificantProteins()
}
)

output$adj_significant = renderDataTable({
  SignificantProteins()$ADJUSTED.Model
}
)

output$unadj_significant = renderDataTable({
  SignificantProteins()$PTM.Model
}
)

output$prot_significant = renderDataTable({
  SignificantProteins()$PROTEIN.Model
}
)

# number of significant proteins
output$number = renderText({
  nrow(SignificantProteins())
})

output$number_adj = renderText({
  nrow(SignificantProteins()$ADJUSTED.Model)
})

output$number_unadj = renderText({
  nrow(SignificantProteins()$PTM.Model)
})

output$number_prot = renderText({
  nrow(SignificantProteins()$PROTEIN.Model)
})

# plot in browser 
observeEvent(input$typeplot, {
  updateSelectInput(session, "whichComp", selected = "all")
})

observeEvent(input$viewresults, {
  insertUI(
    selector = "#comparison_plots",
    ui=tags$div(
      plotOutput("comp_plots", height = "100%", click = "click1"),
      conditionalPanel(condition = "input.typeplot == 'VolcanoPlot' && input.DDA_DIA!='TMT'",
                       h5("Click on plot for details"),
                       verbatimTextOutput("info2")),
      conditionalPanel(condition = "input.typeplot == 'Heatmap'",
                       sliderInput("height", "Plot height", value = 500, min = 200, max = 1300, post = "px"))
    )
  )
}
)

observe({output$comp_plots = renderPlot({
  group_comparison(FALSE, FALSE)}, height = input$height
)
})

plotset = reactive({
  
  if(input$DDA_DIA=="TMT"){
    data_comp = data_comparison()$ComparisonResult
    v1 = data_comp[,1]
    v2 = round(data_comp[,3], 10)
    v3 = round(data_comp[,8], 10)
    v4 = data_comp[,2]
    
  } else{
    v1 = data_comparison()$ComparisonResult[,1]
    v2 = round(data_comparison()$ComparisonResult[,3], 10)
    v3 = round(data_comparison()$ComparisonResult[,8], 10)
    v4 = data_comparison()$ComparisonResult[,2]
    
  }
  
  if (input$logp == "2") {
    v3 = -log2(v3)
  }
  else if (input$logp == "10") {
    v3 = - log10(v3)
  }
  
  df = data.frame(v1,v2,v3,v4)
  df = df[df$v4 == input$whichComp,]
  colnames(df) = c("Protein", "logFC", "logadj.pvalue", "comparison")
  return(df)
})

output$info2 = renderPrint({
  print(nearPoints(plotset(), input$click1, xvar = "logFC", yvar = "logadj.pvalue"))
})

# Assumption plots in browser

output$verify = renderUI ({
  tagList(
    plotOutput("assum_plots", width = "800px", height = "600px"),
    conditionalPanel(condition = "input.whichProt1 != ''",
                     actionButton("saveone1", "Save this plot"),
                     bsTooltip(id = "saveone1", title = "Open plot as pdf.  Popups must be enabled", placement = "bottom", trigger = "hover"),
                     actionButton("saveall1", "Save all plots"),
                     bsTooltip(id = "saveall1", title = "Open pdf of all plots.  Popups must be enabled", placement = "bottom", trigger = "hover")
    )
  )
})

output$assum_plots = renderPlot({
  assumptions1(FALSE, input$whichProt1)})


# downloads
observeEvent(input$saveone1, {
  path = assumptions1(TRUE, input$whichProt1)
  if (input$assum_type == "QQPlots") {
    js = paste("window.open('", path, "QQPlot.pdf')", sep="")
    runjs(js);
  }
  else if (input$type == "ResidualPlots") {
    js = paste("window.open('", path, "ResidualPlots.pdf')", sep="")
    runjs(js);
  }
})

observeEvent(input$saveall1, {
  path = assumptions1(TRUE, "all")
  if (input$assum_type == "QQPlots") {
    js = paste("window.open('", path, "QQPlot.pdf')", sep="")
    runjs(js);
  }
  else if (input$type == "ResidualPlots") {
    js = paste("window.open('", path, "ResidualPlots.pdf')", sep="")
    runjs(js);
  }
})


output$download_compar = downloadHandler(
  filename = function() {
    paste("test_result-", Sys.Date(), ".csv", sep="")
  },
  content = function(file) {
    write.csv(data_comparison()$ComparisonResult, file)
  }
)
output$download_compar_adj = downloadHandler(
  filename = function() {
    paste("adj_data-", Sys.Date(), ".csv", sep="")
  },
  content = function(file) {
    write.csv(data_comparison()$ADJUSTED.Model, file)
  }
)
output$download_compar_unadj = downloadHandler(
  filename = function() {
    paste("unadj_data-", Sys.Date(), ".csv", sep="")
  },
  content = function(file) {
    write.csv(data_comparison()$PTM.Model, file)
  }
)
output$download_compar_prot = downloadHandler(
  filename = function() {
    paste("prot_data-", Sys.Date(), ".csv", sep="")
  },
  content = function(file) {
    write.csv(data_comparison()$PROTEIN.Model, file)
  }
)

output$download_code = downloadHandler(
  filename = function() {
    paste("mstats-code-", Sys.Date(), ".R", sep="")
  },
  content = function(file) {
    writeLines(paste(
      data_comparison_code(), sep = ""), file)
  })

output$download_signif = downloadHandler(
  filename = function() {
    paste("data-", Sys.Date(), ".csv", sep="")
  },
  content = function(file) {
    write.csv(SignificantProteins(), file)
  }
)
output$download_signif_adj = downloadHandler(
  filename = function() {
    paste("adj_data-", Sys.Date(), ".csv", sep="")
  },
  content = function(file) {
    write.csv(SignificantProteins()$ADJUSTED.Model, file)
  }
)
output$download_signif_unadj = downloadHandler(
  filename = function() {
    paste("unadj_data-", Sys.Date(), ".csv", sep="")
  },
  content = function(file) {
    write.csv(SignificantProteins()$PTM.Model, file)
  }
)
output$download_signif_prot = downloadHandler(
  filename = function() {
    paste("prot_data-", Sys.Date(), ".csv", sep="")
  },
  content = function(file) {
    write.csv(SignificantProteins()$PROTEIN.Model, file)
  }
)

observeEvent(input$plotresults, {
  insertUI(
    selector = "#comparison_plots",
    ui=tags$div(
      if (input$typeplot == "VolcanoPlot") {
        js = paste("window.open('", group_comparison(TRUE, TRUE), "VolcanoPlot.pdf')", sep="")
        runjs(js);
      }
      else if (input$typeplot == "Heatmap") {
        js = paste("window.open('", group_comparison(TRUE, TRUE), "Heatmap.pdf')", sep="")
        runjs(js);
      }
      else if (input$typeplot == "ComparisonPlot") {
        js = paste("window.open('", group_comparison(TRUE, TRUE), "ComparisonPlot.pdf')", sep="")
        runjs(js);
      }
    )
  )
})

observeEvent(input$calculate,{
  enable("Design")
  enable("typeplot")
  enable("WhichComp")
  enable("download_code")
})