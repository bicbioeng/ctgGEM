% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/makeSincell.R
\name{makeSincell}
\alias{makeSincell}
\title{A Cell Tree Generating Function using sincell}
\usage{
makeSincell(dataSet, outputDir = tempdir())
}
\arguments{
\item{dataSet}{a ctgGEMset object}

\item{outputDir}{the directory where output should be saved, defaults to
the temporary location returned by \code{tempdir()}}
}
\value{
an updated ctgGEMset object
}
\description{
This function, called by \code{\link{generate_tree}}, creates visualizations
using the data using the \pkg{sincell} package. This function utilizes code
from the sincell vignette R script.
}
\keyword{internal}
