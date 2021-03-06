% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/regression.R
\name{store.reg_predict}
\alias{store.reg_predict}
\title{Store predicted values generated in the regression function}
\usage{
\method{store}{reg_predict}(object, ..., name = "pred_reg")
}
\arguments{
\item{object}{Return value from \code{\link{predict.regression}}}

\item{...}{Additional arguments. Must include data or dataset name (e.g., data = mtcars or data = "mtcars")}

\item{name}{Variable name(s) assigned to predicted values}
}
\description{
Store predicted values generated in the regression function
}
\details{
See \url{http://vnijs.github.io/radiant/quant/regression.html} for an example in Radiant
}

