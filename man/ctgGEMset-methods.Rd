% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/ctgGEMset-methods.R
\name{ctgGEMset-methods}
\alias{ctgGEMset-methods}
\alias{ctgGEMset-methods-methods}
\alias{monocleInfo}
\alias{monocleInfo<-}
\alias{TSCANinfo}
\alias{TSCANinfo<-}
\alias{sincellInfo}
\alias{sincellInfo<-}
\alias{treeList}
\alias{treeList<-}
\alias{originalTrees}
\alias{originalTrees<-}
\title{Methods for the ctgGEMset class}
\usage{
monocleInfo(cs)

monocleInfo(cs, pt) <- value

TSCANinfo(cs)

TSCANinfo(cs) <- value

sincellInfo(cs)

sincellInfo(cs, pt) <- value

treeList(cs)

treeList(cs, tt) <- value

originalTrees(cs)

originalTrees(cs, tt) <- value
}
\arguments{
\item{cs}{A ctgGEMset object}

\item{pt}{The name of the \pkg{monocle} or \pkg{sincell} parameter to store}

\item{value}{\code{monocleInfo(cs)<-}: The value to use as a named parameter for
\code{generate_tree(treeType = "monocle")}

\code{TSCANinfo(cs)<-}: A character vector of the row name of a
single gene in \code{exprsData()} to use for a single gene vs.
pseudotime plot for \code{generate_tree(treeType = "TSCAN")}

\code{sincellInfo(cs)<-}: The value to use as a named parameter for
sincell, used by \code{generate_tree(treeType = "sincell")}}

\item{tt}{The type of tree being stored}
}
\value{
An updated ctgGEMset object, or the contents of a slot of the
ctgGEMset object
}
\description{
These methods operate on ctgGEMset objects. Please note that
treeList<- and originalTrees<- are not intended to be
called directly.
}
\examples{
# load HSMMSingleCell package
library(HSMMSingleCell)

# load the data
data(HSMM_expr_matrix)
data(HSMM_sample_sheet)
data(HSMM_gene_annotation)

# construct a ctgGEMset
dataSet <- ctgGEMset(exprsData = HSMM_expr_matrix,
                        phenoData = HSMM_sample_sheet,
                        featureData = HSMM_gene_annotation)

monocleInfo(dataSet, "gene_id") <- "gene_short_name"
monocleInfo(dataSet, "cell_id_1") <- "MYF5"
monocleInfo(dataSet, "cell_id_2") <- "ANPEP"
monocleInfo(dataSet, "ex_type") <- "FPKM"
monocleInfo(dataSet)

TSCANinfo(dataSet) <- "ENSG00000000003.10"
TSCANinfo(dataSet)

sincellInfo(dataSet, "method") <- "classical-MDS"
sincellInfo(dataSet, "MDS.distance") <- "spearman"
sincellInfo(dataSet, "clust.method") <- "k-medoids"
sincellInfo(dataSet)

# The following two examples will return empty lists, since no trees
# have been generated on this ctgGEMset
trees <- treeList(dataSet)
originalTrees <- originalTrees(dataSet)
}
\keyword{internal}
