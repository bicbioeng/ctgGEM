#' A Cell Tree Generating Function using monocle
#'
#' This function, called by \code{\link{generate_tree}}, creates a cell tree
#' using the \pkg{monocle} package. This function utilizes code
#' from the monocle vignette R script.
#'
#' @param dataSet a ctgGEMset object
#' @return an updated ctgGEMset object
#' @keywords internal
#' @import monocle
#' @import Biobase
#' @import BiocGenerics
#' @importFrom igraph ends E
#' @importFrom methods as

makeMonocle <- function(dataSet) {
    num_cells_expressed <- NULL
    dispersion_empirical <- NULL
    dispersion_fit <- NULL
    mean_expression <- NULL
    error_message <- NULL
    if(is.null(monocleInfo(dataSet)[["gene_id"]])) {
        error_message <- "'gene_id' missing\n"
    }
    if(is.null(monocleInfo(dataSet)[["cell_id_1"]])){
        error_message <- paste0(error_message, "'cell_id_1' missing\n")
    }
    if(is.null(monocleInfo(dataSet)[["cell_id_2"]])){
        error_message <- paste0(error_message, "'cell_id_2' missing\n")
    }
    if(is.null(monocleInfo(dataSet)[["ex_type"]])){
        error_message <- paste0(error_message, "'ex_type' missing\n")
    }
    if(!is.null(error_message)){
        stop(error_message)
    }
    pd <- Biobase::phenoData(dataSet)
    fd <- Biobase::featureData(dataSet)
    gene_expr <- as(as.matrix(Biobase::exprs(dataSet)), "sparseMatrix")
    gene_id <- monocleInfo(dataSet)[["gene_id"]]
    cell_id_1 <- monocleInfo(dataSet)[["cell_id_1"]]
    cell_id_2 <- monocleInfo(dataSet)[["cell_id_2"]]
    ex_type <- monocleInfo(dataSet)[["ex_type"]]
    idx <- which(colnames(fd) %in% gene_id, arr.ind = TRUE)
    colnames(fd)[idx] <- "gene_short_name"
    cell_set <- newCellDataSet(gene_expr, phenoData = pd, featureData = fd)
    if (ex_type == "LTFPKM" || ex_type == "LTTPM") {
        cell_set <- newCellDataSet(gene_expr, phenoData=pd, featureData = fd,
                lowerDetectionLimit=0.5, expressionFamily=VGAM::gaussianff())
    } else {
        if (ex_type == "FPKM" || ex_type == "TPM") {
            # estimate RNA counts
            gene_expr <- relative2abs(cell_set, method = "num_genes")
            gene_expr <- as(as.matrix(gene_expr), "sparseMatrix")
        }
        cell_set <- newCellDataSet(gene_expr, phenoData=pd, featureData = fd,
            lowerDetectionLimit=0.5, expressionFamily=VGAM::negbinomial.size())
    }
    cell_set <- estimateSizeFactors(cell_set)
    cell_set <- estimateDispersions(cell_set)
    #pData(cell_set)$Total_mRNAs <- Matrix::colSums(exprs(cell_set))
    cell_set <- detectGenes(cell_set, min_expr = 0.1)
    cInd1 <- row.names(fData(cell_set)[which(fData(cell_set)[[gene_id]]
                                        == cell_id_1, arr.ind = TRUE), ])
    cInd2 <- row.names(fData(cell_set)[which(fData(cell_set)[[gene_id]]
                                        == cell_id_2, arr.ind = TRUE), ])
    cth <- newCellTypeHierarchy()
    cth <- addCellType(cth, "Cell Type 1",
        classify_func = function(x) {x[cInd1, ] >= 1})
    cth <- addCellType(cth, "Cell Type 2",
        classify_func = function(x) {x[cInd1, ] < 1 & x[cInd2, ] > 1})
    cell_set <- classifyCells(cell_set, cth, 0.1)
    disp_table <- dispersionTable(cell_set)
    unsup_clustering_genes <- subset(disp_table, mean_expression >= 0.1 &
        dispersion_empirical >= 1 * dispersion_fit)
    cell_set <- setOrderingFilter(cell_set, unsup_clustering_genes$gene_id)
    cell_set <- clusterCells(cell_set, num_clusters = 2, method = "DDRTree")
    filename <- as.character(Sys.time())
    filename <- gsub("/", "-", filename)
    filename <- gsub(":", "-", filename)
    filename <- gsub(" ", "_", filename)
    # TODO fix the problem below with prePCA generation, or remove it
    # prePCA <- plot_cell_trajectory(cell_set, 1, 2, color_by ="CellType")
    # grDevices::png( filename = paste0("./CTG-Output/Plots/",filename,
    #                                   "_monoclePrePCA.png"))
    # graphics::plot(prePCA)
    # grDevices::dev.off()
    # originalTrees(dataSet, "monoclePrePCA") <- prePCA
    cell_set <- reduceDimension(cell_set, max_components = 2)
    cell_set <- orderCells(cell_set, reverse = FALSE)
    # more filtering for PCA loading
    cell_set_expressed_genes <- row.names(subset(fData(cell_set),
                                                    num_cells_expressed >= 10))
    cell_set_filtered <- cell_set[cell_set_expressed_genes, ]
    exprs_filtered <- t(t(as.matrix(exprs(cell_set_filtered) /
            pData(cell_set)$Size_Factor)))
    nz_genes <- which(exprs_filtered != 0)
    exprs_filtered[nz_genes] <- log(exprs_filtered[nz_genes] + 1)
    expression_means <- Matrix::rowMeans(exprs_filtered)
    expression_vars <- Matrix::rowMeans((exprs_filtered - expression_means) ^ 2)
    # Filter out genes that are constant across all cells:
    genes_to_keep <- expression_vars > 0
    exprs_filtered <- exprs_filtered[genes_to_keep, ]
    expression_means <- expression_means[genes_to_keep]
    expression_vars <- expression_vars[genes_to_keep]
    # take the top PCA loading genes using sparseMatrix operations using irlba.
    irlba_pca_res <- irlba::irlba(t(exprs_filtered), nu=0,
        center=expression_means, scale=sqrt(expression_vars), right_only=TRUE)$v
    row.names(irlba_pca_res) <- row.names(exprs_filtered)
    PC2_genes <-
        names(sort(abs(irlba_pca_res[, 2]), decreasing = TRUE))[seq_len(100)]
    PC3_genes <-
        names(sort(abs(irlba_pca_res[, 3]), decreasing = TRUE))[seq_len(100)]
    ordering_genes <- union(PC2_genes, PC3_genes)
    cell_set <- setOrderingFilter(cell_set, ordering_genes)
    cell_set <- reduceDimension(cell_set, max_components = 2)
    cell_set <- orderCells(cell_set, reverse = FALSE)
    cell_set <- clusterCells(cell_set, method = "DDRTree")
    postPCA <- plot_cell_trajectory(cell_set, color_by = "CellType")
    grDevices::png(filename = paste0("./CTG-Output/Plots/", filename,
                                        "_monocle.png"))
    graphics::plot(postPCA)
    grDevices::dev.off()
    # ANY CHANGES MADE IN THE FOLLOWING LINE OF CODE MUST BE CHECKED FOR
    # COMPATIBILITY WITH plotOriginalTree
    originalTrees(dataSet, "monocle") <- postPCA
    tree <- MON2CTF(cell_set, filename, 1)
    treeList(dataSet, "monocle") <- tree2igraph(tree)
    dataSet
}

# This helper function converts a monocle cell tree to the standard cell
# tree format and writes its SIF file.
# cell_set = a CellDataSet with tree created by monocle
# timeStamp = the time stamp to be added to the filename
# clusteringType  = the type of clustering in the monocle cell tree (1 =
#    cell type and 2 = time)


MON2CTF <- function(cell_set, timeStamp, clusteringType) {
    if (clusteringType == 1) {
        # get the cell names
        cellNames <- colnames(cell_set@reducedDimS)
        # get the cell types
        cellTypes <- cell_set@phenoData@data$CellType
        # relate the cells by their connecting edges clustered by cell type
        relationships <- paste0(cellNames, "\tcell type clustering\t",
                                cellTypes)
    }
    else if (clusteringType == 2) {
        # get the edges for the cells
        cellEdges <- ends(cell_set@minSpanningTree,
                            es = E(cell_set@minSpanningTree))
        # relate the cells by their connecting edges clustered by time
        relationships <- paste0(cellEdges[, 1], "\ttime clustering\t",
                                cellEdges[, 2])
    }
    # write these relationships to file
    write(
        relationships,
        paste0("./CTG-Output/SIFs/", timeStamp, "_MON_CTF.sif"),
        append = TRUE
    )
    relationships
}