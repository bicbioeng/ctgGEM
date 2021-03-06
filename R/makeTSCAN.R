#' A Cell Tree Generating Function using TSCAN
#'
#' This function, called by \code{\link{generate_tree}}, creates a cell tree
#' using the data and the \pkg{TSCAN} package. This function utilizes code
#' from the TSCAN vignette R script.
#'
#' @param dataSet a ctgGEMset object
#' @param outputDir the directory where output should be saved, defaults to
#' the temporary location returned by \code{tempdir()}
#' @return an updated ctgGEMset object
#' @keywords internal
#' @importFrom utils head tail
#' @importFrom methods is

makeTSCAN <- function(dataSet, outputDir = tempdir()) {
    if (!requireNamespace("TSCAN", quietly = TRUE)) {
        stop(
            "Package 'TSCAN' is required for treeType = 'TSCAN'",
            "but is not installed.  See vignette for details on installing",
            "'TSCAN'",
            call. = FALSE
        )
    }
    # d <- Biobase::exprs(dataSet)
    d <- SummarizedExperiment::assay(dataSet)
    if (length(TSCANinfo(dataSet)) == 0) {
        gene <- NULL
    } else {
        gene <- TSCANinfo(dataSet)
    }
    # preprocess the input data
    procdata <- TSCAN::preprocess(d, minexpr_value = 1)
    # if no data makes it through, re-run with lower threshold
    if (length(procdata[, 1]) < 1) {
        procdata <- TSCAN::preprocess(d, minexpr_value = 0.1)
    }
    # cluster the processed data
    cellmclust <- TSCAN::exprmclust(procdata)
    # get the cell orderings
    cellorder <- TSCAN::TSCANorder(cellmclust)
    # generate the clustering plot
    TSCANclustering <- TSCAN::plotmclust(cellmclust)
    #format the filename
    filename <- format(Sys.time(), "%Y-%m-%d_%H-%M-%S")
    if(is.null(outputDir)){
        fn <- tempfile(paste0(filename,"_TSCANclustering"),
                       tmpdir = file.path(tempdir(),"CTG-Output","Plots"),fileext=".png")
        grDevices::png(filename = fn)
    } else {
        #open png writer
        grDevices::png(filename = file.path(outputDir,"CTG-Output","Plots",
                                            paste0(filename,"_TSCANclustering.png")))
    }
    # generate the plot for clustering
    graphics::plot(TSCANclustering)
    #close the writing device
    grDevices::dev.off()
    
    # store the original plot
    # ANY CHANGES MADE IN THE FOLLOWING LINE OF CODE MUST BE CHECKED FOR
    # COMPATIBILITY WITH plotOriginalTree
    originalTrees(dataSet, "TSCANclustering") <- TSCANclustering
    
    if (!is.null(gene)) {
        # get log of gene
        geneExpr <- log2(d[gene, ] + 1)
        # get ordering
        cellOrderS <-
            TSCAN::TSCANorder(cellmclust, flip = TRUE, orderonly = FALSE)
        # generate a plot for single gene vs the pseudotime
        TSCANsingleGene <- TSCAN::singlegeneplot(geneExpr, cellOrderS)
        if(is.null(outputDir)){
            fn <- tempfile(paste0(filename,"_TSCANsingleGene"),
                           tmpdir = file.path(tempdir(),"CTG-Output","Plots"),fileext=".png")
            grDevices::png(filename = fn)
        } else {
            #open png writer
            grDevices::png(filename = file.path(outputDir,"CTG-Output","Plots",
                                                paste0(filename,"_TSCANsingleGene.png")))
        }
        # generate the plot for backbone tree showing topics
        graphics::plot(TSCANsingleGene)
        #close the writing device
        grDevices::dev.off()
        
        # store the plot
        # ANY CHANGES MADE IN THE FOLLOWING LINE OF CODE MUST BE CHECKED FOR
        # COMPATIBILITY WITH plotOriginalTree
        originalTrees(dataSet, "TSCANsingleGene") <- TSCANsingleGene
    }
    # convert data to standard cell tree format
    tree <- TSC2CTF(cellorder, filename, outputDir)
    treeList(dataSet, "TSCAN") <- tree2igraph(tree)
    dataSet
}

# This helper function converts a TSCAN cell tree to the standard cell tree
# format and writes its SIF file.

TSC2CTF <- function(cellOrder, timeStamp, outputDir = NULL) {
    # cells in cellOrder have relationships with the next cell
    nextCellOrder <- c(tail(cellOrder,-1), NA)
    # relate the cell with the next cell in the ordering
    relationships <-
        paste0(cellOrder, "\tpsuedotime\t", nextCellOrder)
    # remove the last element because it contains no second cell
    relationships <- head(relationships,-1)
    # write these relationships to file
    if(is.null(outputDir)){
        fileName <- tempfile(paste0(timeStamp,"_TSC_CTF"),
                             tmpdir = file.path(tempdir(),"CTG-Output","SIFs"),fileext=".sif")
    } else {
        fileName <- file.path(outputDir,"CTG-Output","SIFs",
                              paste0(timeStamp,"_TSC_CTF.sif"))
    }
    write(relationships,fileName)
    relationships
}
