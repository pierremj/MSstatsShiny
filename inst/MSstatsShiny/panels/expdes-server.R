# toggle input elements and plot

observe({
  if (input$param == "sample") {
    disable("nsample")
    sample_x = TRUE
    }
  else {
    sample_x = input$nsample
    enable("nsample")
  }
   
  if (input$param == "npower") {
    disable("power")
    power_x = TRUE
    }
  else {
    power_x = input$power
    enable("power")
  }
  FDR_x = input$FDR
  FCR_x = input$desirFC
  future_exp = function(){
    exp = designSampleSize(data=data_comparison()$FittedModel,
                            desiredFC = input$desirFC,
                            FDR = FDR_x,
                            numSample = sample_x,
                            power= power_x)
  }
  
#  plot output
  
  output$result_plot = renderPlot({
    designSampleSizePlots(future_exp())
  })
 
  #download
   
  output$download_future = downloadHandler(
    filename = "future_exp.pdf",
    content = function(file) {
      pdf(file)
      designSampleSizePlots(future_exp())
      dev.off()
    })    
  
# hover
  
  output$info = renderText({
    paste0(
      "hover: ", MSstatsShiny::xy_str(input$plot_hover)
    )
  })
})
